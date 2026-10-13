<script>
import produce from 'immer';
import { debounce, isEmpty, isNull } from 'lodash-es';
import { GlAvatarLabeled, GlButton, GlCollapsibleListbox, GlModal, GlToastMixin } from '@gitlab/ui';
import {
  getFirstPropertyValue,
  normalizeHeaders,
  parseIntPagination,
} from '~/lib/utils/common_utils';
import { __, s__ } from '~/locale';
import { createAlert } from '~/alert';
import searchUsersQuery from '~/graphql_shared/queries/users_search_all_paginated.query.graphql';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import { TYPENAME_GROUP } from '~/graphql_shared/constants';
import { fetchGroupEnterpriseUsers } from 'ee_else_ce/api/groups_api';
import { DEFAULT_DEBOUNCE_AND_THROTTLE_MS } from '~/lib/utils/constants';
import {
  PLACEHOLDER_STATUS_AWAITING_APPROVAL,
  PLACEHOLDER_STATUS_REASSIGNING,
} from '~/import_entities/import_groups/constants';
import importSourceUsersQuery from '../graphql/queries/import_source_users.query.graphql';
import groupNonEnterpriseMembersQuery from '../graphql/queries/group_non_enterprise_members.query.graphql';
import importSourceUserReassignMutation from '../graphql/mutations/reassign.mutation.graphql';
import importSourceUserKeepAsPlaceholderMutation from '../graphql/mutations/keep_as_placeholder.mutation.graphql';
import importSourceUseResendNotificationMutation from '../graphql/mutations/resend_notification.mutation.graphql';
import importSourceUserCancelReassignmentMutation from '../graphql/mutations/cancel_reassignment.mutation.graphql';
import BypassConfirmationMessage from './bypass_confirmation_message.vue';

const USERS_PER_PAGE = 20;

const createUserObject = (user) => ({
  ...user,
  text: user.name,
  value: user.id,
});

export default {
  name: 'PlaceholderActions',
  components: {
    BypassConfirmationMessage,
    GlAvatarLabeled,
    GlButton,
    GlCollapsibleListbox,
    GlModal,
  },
  mixins: [GlToastMixin],
  inject: {
    group: {
      default: {},
    },
    restrictReassignmentToEnterprise: {
      default: false,
    },
    allowNonEnterprisePlaceholderReassignment: {
      default: false,
    },
    allowInactivePlaceholderReassignment: {
      default: false,
    },
    allowBypassPlaceholderConfirmation: {
      default: null,
    },
  },
  props: {
    sourceUser: {
      type: Object,
      required: false,
      default: () => ({}),
    },
  },
  emits: ['confirm'],

  data() {
    return {
      isConfirmLoading: false,
      isCancelLoading: false,
      isNotifyLoading: false,
      apolloIsLoadingInitial: true,
      apolloIsLoadingMore: false,
      isValidated: false,
      search: '',
      selectedUserToReassign: null,
      enterpriseUsers: [],
      enterpriseUsersPageInfo: {
        nextPage: null,
      },
      enterpriseUsersIsLoadingInitial: false,
      enterpriseUsersIsLoadingMore: false,
      hasShownListbox: false,
    };
  },

  apollo: {
    // eslint-disable-next-line @gitlab/vue-no-undef-apollo-properties
    users: {
      query: searchUsersQuery,
      variables() {
        return {
          ...this.queryVariables,
        };
      },
      result() {
        this.apolloIsLoadingInitial = false;
      },
      skip() {
        return this.restrictReassignmentToEnterprise;
      },
      error() {
        this.onError();
      },
    },
    // eslint-disable-next-line @gitlab/vue-no-undef-apollo-properties
    nonEnterpriseMembers: {
      query: groupNonEnterpriseMembersQuery,
      variables() {
        return { ...this.nonEnterpriseMembersQueryVariables };
      },
      update(data) {
        return data.users;
      },
      result() {
        this.apolloIsLoadingInitial = false;
      },
      skip() {
        return !this.isNonEnterpriseMembersMode || !this.hasShownListbox;
      },
      error() {
        this.apolloIsLoadingInitial = false;
        this.onError();
      },
    },
  },

  computed: {
    isNonEnterpriseMembersMode() {
      return (
        this.restrictReassignmentToEnterprise && this.allowNonEnterprisePlaceholderReassignment
      );
    },

    isEnterpriseRestMode() {
      return (
        this.restrictReassignmentToEnterprise && !this.allowNonEnterprisePlaceholderReassignment
      );
    },

    nonEnterpriseMembersQueryVariables() {
      return {
        groupId: convertToGraphQLId(TYPENAME_GROUP, this.group.id),
        search: this.search,
        first: USERS_PER_PAGE,
        humans: true,
        ...(this.allowInactivePlaceholderReassignment ? {} : { active: true }),
      };
    },

    queryVariables() {
      const query = {
        first: USERS_PER_PAGE,
        ...(this.allowInactivePlaceholderReassignment ? {} : { active: true }),
        humans: true,
        search: this.search,
      };

      return query;
    },

    hasNextPage() {
      if (this.isNonEnterpriseMembersMode) {
        return (
          Boolean(this.enterpriseUsersPageInfo.nextPage) ||
          Boolean(this.nonEnterpriseMembers?.pageInfo?.hasNextPage)
        );
      }

      if (this.isEnterpriseRestMode) {
        return Boolean(this.enterpriseUsersPageInfo.nextPage);
      }

      return this.users?.pageInfo?.hasNextPage;
    },

    isLoading() {
      if (this.isNonEnterpriseMembersMode) {
        return (
          (this.$apollo.queries.nonEnterpriseMembers.loading ||
            this.enterpriseUsersIsLoadingInitial) &&
          !this.apolloIsLoadingMore &&
          !this.enterpriseUsersIsLoadingMore
        );
      }

      if (this.isEnterpriseRestMode) {
        return this.enterpriseUsersIsLoadingInitial;
      }

      return this.$apollo.queries.users.loading && !this.apolloIsLoadingMore;
    },

    isLoadingMore() {
      if (this.isNonEnterpriseMembersMode) {
        return this.apolloIsLoadingMore || this.enterpriseUsersIsLoadingMore;
      }

      if (this.isEnterpriseRestMode) {
        return this.enterpriseUsersIsLoadingMore;
      }

      return this.apolloIsLoadingMore;
    },

    isLoadingInitial() {
      if (this.isNonEnterpriseMembersMode) {
        return (
          (this.hasShownListbox && this.apolloIsLoadingInitial) ||
          this.enterpriseUsersIsLoadingInitial
        );
      }

      if (this.isEnterpriseRestMode) {
        return this.enterpriseUsersIsLoadingInitial;
      }

      return this.apolloIsLoadingInitial;
    },

    userSelectInvalid() {
      return this.isValidated && !this.selectedUserToReassign;
    },

    userItems() {
      if (this.isNonEnterpriseMembersMode) {
        return this.mergedNonEnterpriseItems;
      }

      if (this.isEnterpriseRestMode) {
        return this.enterpriseUsers?.map((user) => this.createUserObjectFromEnterprise(user));
      }

      return this.users?.nodes?.map((user) => createUserObject(user));
    },

    // Enterprise users are not necessarily members of this group, and members of this group are
    // not necessarily enterprise users, so both sources are searched independently and merged
    // (deduped by user) when the "also allow non-enterprise members" setting is on.
    mergedNonEnterpriseItems() {
      const enterpriseItems = this.enterpriseUsers.map((user) =>
        this.createUserObjectFromEnterprise(user),
      );
      const nonEnterpriseItems =
        this.nonEnterpriseMembers?.nodes?.map((node) => createUserObject(node)) || [];
      const seenValues = new Set();

      return [...enterpriseItems, ...nonEnterpriseItems].filter((item) => {
        if (seenValues.has(item.value)) {
          return false;
        }

        seenValues.add(item.value);
        return true;
      });
    },

    dontReassignSelected() {
      return !isNull(this.selectedUserToReassign) && isEmpty(this.selectedUserToReassign);
    },

    toggleText() {
      if (this.dontReassignSelected) {
        return s__('UserMapping|Do not reassign');
      }

      if (this.selectedUserToReassign) {
        return `@${this.selectedUserToReassign.username}`;
      }

      return s__('UserMapping|Select user');
    },

    selectedUserValue() {
      return this.selectedUserToReassign?.value;
    },

    confirmOrReassignButtonText() {
      return this.dontReassignSelected ? __('Confirm') : s__('UserMapping|Reassign');
    },

    statusIsAwaitingApproval() {
      return this.sourceUser.status === PLACEHOLDER_STATUS_AWAITING_APPROVAL;
    },
    statusIsReassigning() {
      return this.sourceUser.status === PLACEHOLDER_STATUS_REASSIGNING;
    },
  },

  created() {
    if (this.statusIsAwaitingApproval || this.statusIsReassigning) {
      this.selectedUserToReassign = this.sourceUser.reassignToUser;
    }

    this.debouncedSetSearch = debounce(this.setSearch, DEFAULT_DEBOUNCE_AND_THROTTLE_MS);
  },

  methods: {
    async fetchEnterpriseUsers(page) {
      try {
        const { data, headers } = await fetchGroupEnterpriseUsers(this.group.id, {
          page,
          per_page: USERS_PER_PAGE,
          search: this.search,
        });

        this.enterpriseUsersPageInfo = parseIntPagination(normalizeHeaders(headers));
        this.enterpriseUsers.push(...data);
      } catch (error) {
        this.onError();
      }
    },
    async loadInitialEnterpriseUsers() {
      if (!this.restrictReassignmentToEnterprise || this.enterpriseUsers.length > 0) {
        return;
      }

      this.enterpriseUsersIsLoadingInitial = true;
      await this.fetchEnterpriseUsers(1);
      this.enterpriseUsersIsLoadingInitial = false;
    },

    onListboxShown() {
      this.loadInitialEnterpriseUsers();
      this.hasShownListbox = true;
    },

    async loadMoreEnterpriseUsers() {
      this.enterpriseUsersIsLoadingMore = true;
      await this.fetchEnterpriseUsers(this.enterpriseUsersPageInfo.nextPage);
      this.enterpriseUsersIsLoadingMore = false;
    },

    async loadMoreNonEnterpriseMembers() {
      this.apolloIsLoadingMore = true;

      try {
        await this.$apollo.queries.nonEnterpriseMembers.fetchMore({
          variables: {
            ...this.nonEnterpriseMembersQueryVariables,
            after: this.nonEnterpriseMembers.pageInfo?.endCursor,
          },
          updateQuery: (previousResult, { fetchMoreResult }) => {
            return produce(fetchMoreResult, (draftData) => {
              draftData.users.nodes = [...previousResult.users.nodes, ...draftData.users.nodes];
            });
          },
        });
      } catch (error) {
        this.onError();
      } finally {
        this.apolloIsLoadingMore = false;
      }
    },

    async loadMoreUsers() {
      if (!this.hasNextPage) return;

      if (this.isNonEnterpriseMembersMode) {
        if (this.enterpriseUsersPageInfo.nextPage) {
          this.loadMoreEnterpriseUsers();
        }

        if (this.nonEnterpriseMembers?.pageInfo?.hasNextPage) {
          this.loadMoreNonEnterpriseMembers();
        }

        return;
      }

      if (this.isEnterpriseRestMode) {
        this.loadMoreEnterpriseUsers();
        return;
      }

      this.apolloIsLoadingMore = true;

      try {
        await this.$apollo.queries.users.fetchMore({
          variables: {
            ...this.queryVariables,
            after: this.users.pageInfo?.endCursor,
          },
          updateQuery: (previousResult, { fetchMoreResult }) => {
            return produce(fetchMoreResult, (draftData) => {
              draftData.users.nodes = [...previousResult.users.nodes, ...draftData.users.nodes];
            });
          },
        });
      } catch (error) {
        this.onError();
      } finally {
        this.apolloIsLoadingMore = false;
      }
    },

    onError() {
      createAlert({
        message: __('There was a problem fetching users.'),
      });
    },

    setSearch(searchTerm) {
      this.search = searchTerm;

      if (this.restrictReassignmentToEnterprise) {
        this.enterpriseUsers = [];
        this.loadInitialEnterpriseUsers();
      }
    },

    createUserObjectFromEnterprise({
      id,
      username,
      web_url: webUrl,
      web_path: webPath,
      avatar_url: avatarUrl,
      name,
    }) {
      const gid = `gid://gitlab/User/${id}`;

      return {
        username,
        webUrl,
        webPath,
        avatarUrl,
        id: gid,
        text: name,
        value: gid,
      };
    },

    onSelect(value) {
      if (value === '') {
        this.selectedUserToReassign = {};
        try {
          this.$refs.userSelect.closeAndFocus();
        } catch {
          // ignore when we can't close listbox
        }
      } else {
        this.selectedUserToReassign = this.userItems.find((user) => user.value === value);
      }
    },

    onNotify() {
      this.isNotifyLoading = true;
      this.$apollo
        .mutate({
          mutation: importSourceUseResendNotificationMutation,
          variables: {
            id: this.sourceUser.id,
          },
        })
        .then(({ data }) => {
          const { errors } = getFirstPropertyValue(data);
          if (errors?.length) {
            createAlert({ message: errors.join() });
          } else {
            this.$toast.show(s__('UserMapping|Notification email sent.'));
          }
        })
        .catch((error) => {
          createAlert({
            message:
              error?.message || s__('UserMapping|Notification email could not be sent again.'),
          });
        })
        .finally(() => {
          this.isNotifyLoading = false;
        });
    },
    onCancel() {
      this.isCancelLoading = true;
      this.$apollo
        .mutate({
          mutation: importSourceUserCancelReassignmentMutation,
          variables: {
            id: this.sourceUser.id,
          },
        })
        .then(({ data }) => {
          const { errors } = getFirstPropertyValue(data);
          if (errors?.length) {
            createAlert({ message: errors.join() });
          }
        })
        .catch(() => {
          createAlert({
            message: s__('UserMapping|Reassigning placeholder user could not be canceled.'),
          });
        })
        .finally(() => {
          this.isCancelLoading = false;
        });
    },
    confirmUser() {
      const hasSelectedUserToReassign = Boolean(this.selectedUserToReassign.id);
      this.isConfirmLoading = true;
      this.$apollo
        .mutate({
          mutation: hasSelectedUserToReassign
            ? importSourceUserReassignMutation
            : importSourceUserKeepAsPlaceholderMutation,
          variables: {
            id: this.sourceUser.id,
            ...(hasSelectedUserToReassign ? { userId: this.selectedUserToReassign.id } : {}),
          },
          refetchQueries: [hasSelectedUserToReassign ? {} : importSourceUsersQuery],
        })
        .then(({ data }) => {
          const { errors } = getFirstPropertyValue(data);
          if (errors?.length) {
            createAlert({ message: errors.join() });
          } else if (!hasSelectedUserToReassign) {
            this.$emit('confirm');
          }
        })
        .catch(() => {
          createAlert({
            message: s__('UserMapping|Placeholder user could not be reassigned.'),
          });
        })
        .finally(() => {
          this.isConfirmLoading = false;
        });
    },
    onConfirmOrReassign() {
      this.isValidated = true;

      if (this.userSelectInvalid) {
        return;
      }

      if (
        this.allowBypassPlaceholderConfirmation &&
        !this.dontReassignSelected &&
        this.$refs.confirmModal
      ) {
        this.$refs.confirmModal.show();
      } else {
        this.confirmUser();
      }
    },
  },

  confirmModal: {
    actionPrimary: {
      text: s__('UserMapping|Confirm reassignment'),
    },
    actionSecondary: {
      text: __('Cancel'),
    },
  },
};
</script>

<template>
  <div class="gl-flex gl-flex-wrap gl-items-start gl-gap-3">
    <div class="gl-w-full @xl/panel:gl-w-28">
      <gl-collapsible-listbox
        ref="userSelect"
        block
        is-check-centered
        toggle-class="!gl-w-full !@xl/panel:gl-w-28"
        :class="{ 'is-invalid': userSelectInvalid || sourceUser.reassignmentError }"
        :header-text="s__('UserMapping|Reassign to')"
        :toggle-text="toggleText"
        :disabled="statusIsAwaitingApproval || statusIsReassigning"
        :loading="isLoadingInitial"
        :items="userItems"
        :selected="selectedUserValue"
        searchable
        :searching="isLoading"
        infinite-scroll
        :infinite-scroll-loading="isLoadingMore"
        @shown="onListboxShown"
        @search="debouncedSetSearch"
        @select="onSelect"
        @bottom-reached="loadMoreUsers"
      >
        <template #list-item="{ item }">
          <gl-avatar-labeled
            shape="circle"
            :size="32"
            :src="item.avatarUrl"
            :label="item.text"
            :sub-label="`@${item.username}`"
          />
        </template>

        <template #footer>
          <div
            class="gl-flex gl-flex-col gl-border-t-1 gl-border-t-dropdown !gl-p-2 !gl-pt-0 gl-border-t-solid"
          >
            <gl-button
              category="tertiary"
              class="gl-mt-2 !gl-justify-start"
              data-testid="dont-reassign-button"
              @click="onSelect('')"
            >
              {{ s__('UserMapping|Do not reassign') }}
            </gl-button>
          </div>
        </template>
      </gl-collapsible-listbox>

      <span v-if="userSelectInvalid" class="invalid-feedback">
        {{ __('This field is required.') }}
      </span>
      <span v-if="sourceUser.reassignmentError" class="invalid-feedback">
        {{ sourceUser.reassignmentError }}
      </span>
    </div>

    <template v-if="statusIsAwaitingApproval || statusIsReassigning">
      <gl-button
        :disabled="statusIsReassigning"
        :loading="isNotifyLoading"
        data-testid="notify-button"
        @click="onNotify"
        >{{ s__('UserMapping|Notify again') }}</gl-button
      >
      <gl-button
        :disabled="statusIsReassigning"
        :loading="isCancelLoading"
        data-testid="cancel-button"
        @click="onCancel"
        >{{ __('Cancel') }}</gl-button
      >
    </template>
    <template v-else>
      <gl-button
        variant="confirm"
        :loading="isConfirmLoading"
        data-testid="confirm-button"
        @click="onConfirmOrReassign"
        >{{ confirmOrReassignButtonText }}</gl-button
      >
      <gl-modal
        v-if="allowBypassPlaceholderConfirmation"
        ref="confirmModal"
        modal-id="placeholder-reassignment-confirm-modal"
        data-testid="confirm-modal"
        :title="s__('UserMapping|Confirm reassignment')"
        :action-primary="$options.confirmModal.actionPrimary"
        :action-secondary="$options.confirmModal.actionSecondary"
        @primary="confirmUser"
      >
        <bypass-confirmation-message />
      </gl-modal>
    </template>
  </div>
</template>

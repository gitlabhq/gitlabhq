<script>
import produce from 'immer';
import { debounce, isEmpty, isNull } from 'lodash';
import { GlAvatarLabeled, GlButton, GlCollapsibleListbox } from '@gitlab/ui';
import { __, s__ } from '~/locale';
import { createAlert } from '~/alert';
import { getFirstPropertyValue } from '~/lib/utils/common_utils';

import searchUsersQuery from '~/graphql_shared/queries/users_search_all_paginated.query.graphql';
import { DEFAULT_DEBOUNCE_AND_THROTTLE_MS } from '~/lib/utils/constants';
import {
  PLACEHOLDER_STATUS_AWAITING_APPROVAL,
  PLACEHOLDER_STATUS_REASSIGNING,
} from '~/import_entities/import_groups/constants';
import importSourceUsersQuery from '../graphql/queries/import_source_users.query.graphql';
import importSourceUserReassignMutation from '../graphql/mutations/reassign.mutation.graphql';
import importSourceUserKeepAsPlaceholderMutation from '../graphql/mutations/keep_as_placeholder.mutation.graphql';
import importSourceUseResendNotificationMutation from '../graphql/mutations/resend_notification.mutation.graphql';
import importSourceUserCancelReassignmentMutation from '../graphql/mutations/cancel_reassignment.mutation.graphql';

const USERS_PER_PAGE = 20;

const createUserObject = (user) => ({
  ...user,
  text: user.name,
  value: user.id,
});

export default {
  name: 'PlaceholderActions',
  components: {
    GlAvatarLabeled,
    GlButton,
    GlCollapsibleListbox,
  },
  props: {
    sourceUser: {
      type: Object,
      required: false,
      default: () => ({}),
    },
  },

  data() {
    return {
      isConfirmLoading: false,
      isCancelLoading: false,
      isNotifyLoading: false,
      isLoadingInitial: true,
      isLoadingMore: false,
      isValidated: false,
      search: '',
      selectedUserToReassign: null,
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
        this.isLoadingInitial = false;
      },
      error() {
        this.onError();
      },
    },
  },

  computed: {
    queryVariables() {
      return {
        first: USERS_PER_PAGE,
        active: true,
        humans: true,
        search: this.search,
      };
    },

    hasNextPage() {
      return this.users?.pageInfo?.hasNextPage;
    },

    isLoading() {
      return this.$apollo.queries.users.loading && !this.isLoadingMore;
    },

    userSelectInvalid() {
      return this.isValidated && !this.selectedUserToReassign;
    },

    userItems() {
      return this.users?.nodes?.map((user) => createUserObject(user));
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

    confirmText() {
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
    async loadMoreUsers() {
      if (!this.hasNextPage) return;

      this.isLoadingMore = true;

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
        this.isLoadingMore = false;
      }
    },

    onError() {
      createAlert({
        message: __('There was a problem fetching users.'),
      });
    },

    setSearch(searchTerm) {
      this.search = searchTerm;
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
    onConfirm() {
      this.isValidated = true;
      if (!this.userSelectInvalid) {
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
      }
    },
  },
};
</script>

<template>
  <div class="gl-flex gl-items-start gl-gap-3">
    <div class="gl-w-28">
      <gl-collapsible-listbox
        ref="userSelect"
        block
        is-check-centered
        toggle-class="!gl-w-28"
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
    <gl-button
      v-else
      variant="confirm"
      :loading="isConfirmLoading"
      data-testid="confirm-button"
      @click="onConfirm"
      >{{ confirmText }}</gl-button
    >
  </div>
</template>

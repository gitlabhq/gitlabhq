<script>
import { GlTokenSelector, GlIcon, GlAvatar, GlLink, GlSkeletonLoader } from '@gitlab/ui';
import { debounce } from 'lodash';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import userSearchQuery from '~/graphql_shared/queries/users_search.query.graphql';
import { n__ } from '~/locale';
import SidebarParticipant from '~/sidebar/components/assignees/sidebar_participant.vue';
import { DEFAULT_DEBOUNCE_AND_THROTTLE_MS } from '~/lib/utils/constants';
import localUpdateWorkItemMutation from '../graphql/local_update_work_item.mutation.graphql';
import { i18n } from '../constants';

function isTokenSelectorElement(el) {
  return el?.classList.contains('gl-token-close') || el?.classList.contains('dropdown-item');
}

function addClass(el) {
  return {
    ...el,
    class: 'gl-bg-transparent',
  };
}

export default {
  components: {
    GlTokenSelector,
    GlIcon,
    GlAvatar,
    GlLink,
    GlSkeletonLoader,
    SidebarParticipant,
  },
  inject: ['fullPath'],
  props: {
    workItemId: {
      type: String,
      required: true,
    },
    assignees: {
      type: Array,
      required: true,
    },
  },
  data() {
    return {
      isEditing: false,
      searchStarted: false,
      localAssignees: this.assignees.map(addClass),
      searchKey: '',
      searchUsers: [],
    };
  },
  apollo: {
    searchUsers: {
      query() {
        return userSearchQuery;
      },
      variables() {
        return {
          fullPath: this.fullPath,
          search: this.searchKey,
        };
      },
      skip() {
        return !this.searchStarted;
      },
      update(data) {
        return data.workspace?.users?.nodes.map((node) => addClass({ ...node, ...node.user }));
      },
      error() {
        this.$emit('error', i18n.fetchError);
      },
    },
  },
  computed: {
    assigneeListEmpty() {
      return this.assignees.length === 0;
    },
    containerClass() {
      return !this.isEditing ? 'gl-shadow-none! gl-bg-transparent!' : '';
    },
    isLoading() {
      return this.$apollo.queries.searchUsers.loading;
    },
    assigneeText() {
      return n__('WorkItem|Assignee', 'WorkItem|Assignees', this.localAssignees.length);
    },
  },
  watch: {
    assignees(newVal) {
      if (!this.isEditing) {
        this.localAssignees = newVal.map(addClass);
      }
    },
  },
  created() {
    this.debouncedSearchKeyUpdate = debounce(this.setSearchKey, DEFAULT_DEBOUNCE_AND_THROTTLE_MS);
  },
  methods: {
    getUserId(id) {
      return getIdFromGraphQLId(id);
    },
    setAssignees(e) {
      if (isTokenSelectorElement(e.relatedTarget) || !this.isEditing) return;
      this.isEditing = false;
      this.$apollo.mutate({
        mutation: localUpdateWorkItemMutation,
        variables: {
          input: {
            id: this.workItemId,
            assignees: this.localAssignees,
          },
        },
      });
    },
    handleFocus() {
      this.isEditing = true;
      this.searchStarted = true;
    },
    async focusTokenSelector() {
      this.handleFocus();
      await this.$nextTick();
      this.$refs.tokenSelector.focusTextInput();
    },
    handleMouseOver() {
      this.timeout = setTimeout(() => {
        this.searchStarted = true;
      }, DEFAULT_DEBOUNCE_AND_THROTTLE_MS);
    },
    handleMouseOut() {
      clearTimeout(this.timeout);
    },
    setSearchKey(value) {
      this.searchKey = value;
    },
  },
};
</script>

<template>
  <div class="form-row gl-mb-5 work-item-assignees gl-relative">
    <span
      class="gl-font-weight-bold col-lg-2 col-3 gl-pt-2 min-w-fit-content gl-overflow-wrap-break"
      data-testid="assignees-title"
      >{{ assigneeText }}</span
    >
    <gl-token-selector
      ref="tokenSelector"
      v-model="localAssignees"
      :container-class="containerClass"
      class="gl-flex-grow-1 gl-border gl-border-white gl-hover-border-gray-200 gl-rounded-base col-9 gl-align-self-start"
      :dropdown-items="searchUsers"
      :loading="isLoading"
      @input="focusTokenSelector"
      @text-input="debouncedSearchKeyUpdate"
      @focus="handleFocus"
      @blur="setAssignees"
      @mouseover.native="handleMouseOver"
      @mouseout.native="handleMouseOut"
    >
      <template #empty-placeholder>
        <div
          class="add-assignees gl-min-w-fit-content gl-display-flex gl-align-items-center gl-text-gray-300 gl-pr-4 gl-top-2"
          data-testid="empty-state"
        >
          <gl-icon name="profile" />
          <span class="gl-ml-2">{{ __('Add assignees') }}</span>
        </div>
      </template>
      <template #token-content="{ token }">
        <gl-link
          :href="token.webUrl"
          :title="token.name"
          :data-user-id="getUserId(token.id)"
          data-placement="top"
          class="gl-text-decoration-none! gl-text-body! gl-display-flex gl-md-display-inline-flex! gl-align-items-center js-user-link"
        >
          <gl-avatar :size="24" :src="token.avatarUrl" />
          <span class="gl-pl-2">{{ token.name }}</span>
        </gl-link>
      </template>
      <template #dropdown-item-content="{ dropdownItem }">
        <sidebar-participant :user="dropdownItem" />
      </template>
      <template #loading-content>
        <gl-skeleton-loader :height="170">
          <rect width="380" height="20" x="10" y="15" rx="4" />
          <rect width="280" height="20" x="10" y="50" rx="4" />
          <rect width="380" height="20" x="10" y="95" rx="4" />
          <rect width="280" height="20" x="10" y="130" rx="4" />
        </gl-skeleton-loader>
      </template>
    </gl-token-selector>
  </div>
</template>

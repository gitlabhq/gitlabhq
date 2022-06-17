<script>
import { GlTokenSelector, GlIcon, GlAvatar, GlLink } from '@gitlab/ui';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import localUpdateWorkItemMutation from '../graphql/local_update_work_item.mutation.graphql';

function isClosingIcon(el) {
  return el?.classList.contains('gl-token-close');
}

export default {
  components: {
    GlTokenSelector,
    GlIcon,
    GlAvatar,
    GlLink,
  },
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
      localAssignees: this.assignees.map((assignee) => ({
        ...assignee,
        class: 'gl-bg-transparent!',
      })),
    };
  },
  computed: {
    assigneeIds() {
      return this.localAssignees.map((assignee) => assignee.id);
    },
    assigneeListEmpty() {
      return this.assignees.length === 0;
    },
    containerClass() {
      return !this.isEditing ? 'gl-shadow-none! gl-bg-transparent!' : '';
    },
  },
  methods: {
    getUserId(id) {
      return getIdFromGraphQLId(id);
    },
    setAssignees(e) {
      if (isClosingIcon(e.relatedTarget) || !this.isEditing) return;
      this.isEditing = false;
      this.$apollo.mutate({
        mutation: localUpdateWorkItemMutation,
        variables: {
          input: {
            id: this.workItemId,
            assigneeIds: this.assigneeIds,
          },
        },
      });
    },
    async focusTokenSelector() {
      this.isEditing = true;
      await this.$nextTick();
      this.$refs.tokenSelector.focusTextInput();
    },
  },
};
</script>

<template>
  <div class="gl-display-flex gl-mb-4 work-item-assignees gl-relative">
    <span class="gl-font-weight-bold gl-w-15 gl-pt-2" data-testid="assignees-title">{{
      __('Assignee(s)')
    }}</span>
    <gl-token-selector
      ref="tokenSelector"
      v-model="localAssignees"
      hide-dropdown-with-no-items
      :container-class="containerClass"
      class="gl-w-full gl-border gl-border-white gl-hover-border-gray-200 gl-rounded-base"
      @token-remove="focusTokenSelector"
      @focus="isEditing = true"
      @blur="setAssignees"
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
    </gl-token-selector>
  </div>
</template>

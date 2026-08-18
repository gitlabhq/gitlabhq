<script>
import { GlButton } from '@gitlab/ui';
import { TYPE_ISSUE } from '~/issues/constants';
import CollapsedAssigneeList from './collapsed_assignee_list.vue';
import UncollapsedAssigneeList from './uncollapsed_assignee_list.vue';

export default {
  name: 'AssigneesList',
  components: {
    GlButton,
    CollapsedAssigneeList,
    UncollapsedAssigneeList,
  },
  props: {
    users: {
      type: Array,
      required: true,
    },
    editable: {
      type: Boolean,
      required: true,
    },
    issuableType: {
      type: String,
      required: false,
      default: TYPE_ISSUE,
    },
  },
  emits: ['assign-self'],
  computed: {
    hasNoUsers() {
      return !this.users.length;
    },
    sortedAssigness() {
      const canMergeUsers = this.users.filter((user) => user.can_merge);
      const canNotMergeUsers = this.users.filter((user) => !user.can_merge);
      return [...canMergeUsers, ...canNotMergeUsers];
    },
  },
  methods: {
    assignSelf() {
      this.$emit('assign-self');
    },
  },
};
</script>

<template>
  <div>
    <collapsed-assignee-list :users="sortedAssigness" :issuable-type="issuableType" />

    <div class="value hide-collapsed">
      <span v-if="hasNoUsers" class="no-value" data-testid="no-value">
        {{ __('None') }}
        <template v-if="editable">
          -
          <gl-button
            class="!gl-text-inherit hover:!gl-text-link"
            variant="link"
            data-testid="assign-yourself"
            @click="assignSelf"
          >
            {{ __('assign yourself') }}
          </gl-button>
        </template>
      </span>

      <uncollapsed-assignee-list v-else :users="sortedAssigness" :issuable-type="issuableType" />
    </div>
  </div>
</template>

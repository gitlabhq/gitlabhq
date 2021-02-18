<script>
import { GlButton } from '@gitlab/ui';
import { n__ } from '~/locale';
import UncollapsedAssigneeList from '~/sidebar/components/assignees/uncollapsed_assignee_list.vue';

export default {
  components: {
    GlButton,
    UncollapsedAssigneeList,
  },
  props: {
    users: {
      type: Array,
      required: true,
    },
    issuableType: {
      type: String,
      required: false,
      default: 'issue',
    },
  },
  computed: {
    assigneesText() {
      return n__('Assignee', '%d Assignees', this.users.length);
    },
    emptyUsers() {
      return this.users.length === 0;
    },
  },
};
</script>

<template>
  <div class="gl-display-flex gl-flex-direction-column">
    <div v-if="emptyUsers" data-testid="none">
      <span> {{ __('None') }} -</span>
      <gl-button
        data-testid="assign-yourself"
        category="tertiary"
        variant="link"
        @click="$emit('assign-self')"
      >
        <span class="gl-text-gray-500 gl-hover-text-blue-800">{{ __('assign yourself') }}</span>
      </gl-button>
    </div>
    <uncollapsed-assignee-list v-else :users="users" :issuable-type="issuableType" />
  </div>
</template>

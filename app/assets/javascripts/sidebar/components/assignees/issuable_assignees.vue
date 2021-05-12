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
    signedIn: {
      type: Boolean,
      required: false,
      default: false,
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
  <div class="gl-display-flex gl-flex-direction-column issuable-assignees">
    <div
      v-if="emptyUsers"
      class="gl-display-flex gl-align-items-center gl-text-gray-500 gl-mt-2 hide-collapsed"
      data-testid="none"
    >
      <span> {{ __('None') }}</span>
      <template v-if="signedIn">
        <span class="gl-ml-2">-</span>
        <gl-button
          data-testid="assign-yourself"
          category="tertiary"
          variant="link"
          class="gl-ml-2"
          @click="$emit('assign-self')"
        >
          <span class="gl-text-gray-500 gl-hover-text-blue-800">{{ __('assign yourself') }}</span>
        </gl-button>
      </template>
    </div>
    <uncollapsed-assignee-list
      v-else
      :users="users"
      :issuable-type="issuableType"
      class="gl-text-gray-800 gl-mt-2 hide-collapsed"
    />
  </div>
</template>

<script>
import { GlTooltipDirective, GlIcon } from '@gitlab/ui';
import UserDate from '~/vue_shared/components/user_date.vue';

export default {
  components: { UserDate, GlIcon },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    member: {
      type: Object,
      required: true,
    },
  },
  computed: {
    userCreated() {
      return this.member.user?.createdAt;
    },
    lastActivity() {
      return this.member.user?.lastActivityOn;
    },
    accessGranted() {
      return this.member.requestAcceptedAt || this.member.createdAt;
    },
  },
};
</script>

<template>
  <div class="gl-display-flex gl-flex-direction-column gl-gap-2">
    <div v-if="userCreated" class="gl-display-flex gl-gap-3">
      <gl-icon
        ref="userCreated"
        v-gl-tooltip.${userCreated}
        class="gl-ml-2 -gl-mr-2 gl-text-gray-500"
        name="assignee"
        :title="s__('Members|User created')"
      />
      <user-date :date="userCreated" />
    </div>
    <div v-if="accessGranted" class="gl-display-flex gl-gap-3">
      <gl-icon
        ref="memberCreatedAt"
        v-gl-tooltip.${memberCreatedAt}
        class="gl-text-gray-500"
        name="check"
        :title="s__('Members|Access granted')"
      />
      <user-date :date="accessGranted" />
    </div>
    <div v-if="lastActivity" class="gl-display-flex gl-gap-3">
      <gl-icon
        ref="lastActivity"
        v-gl-tooltip.${lastActivity}
        class="gl-text-gray-500"
        name="hourglass"
        :title="s__('Members|Last activity')"
      />
      <user-date :date="lastActivity" />
    </div>
  </div>
</template>

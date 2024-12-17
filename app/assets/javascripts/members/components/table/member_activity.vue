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
      return this.member.inviteAcceptedAt || this.member.requestAcceptedAt || this.member.createdAt;
    },
  },
};
</script>

<template>
  <div class="gl-flex gl-flex-col gl-gap-2">
    <div v-if="userCreated" class="gl-flex gl-gap-3">
      <gl-icon
        ref="userCreated"
        v-gl-tooltip.${userCreated}
        class="-gl-mr-2 gl-ml-2 gl-text-subtle"
        name="assignee"
        :title="s__('Members|User created')"
      />
      <user-date :date="userCreated" />
    </div>
    <div v-if="accessGranted" class="gl-flex gl-gap-3">
      <gl-icon
        ref="memberCreatedAt"
        v-gl-tooltip.${memberCreatedAt}
        class="gl-text-subtle"
        name="check"
        :title="s__('Members|Access granted')"
      />
      <user-date data-testid="access-granted-date" :date="accessGranted" />
    </div>
    <div v-if="lastActivity" class="gl-flex gl-gap-3">
      <gl-icon
        ref="lastActivity"
        v-gl-tooltip.${lastActivity}
        class="gl-text-subtle"
        name="hourglass"
        :title="s__('Members|Last activity')"
      />
      <user-date :date="lastActivity" />
    </div>
  </div>
</template>

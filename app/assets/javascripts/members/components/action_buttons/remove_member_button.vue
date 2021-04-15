<script>
import { GlButton, GlTooltipDirective } from '@gitlab/ui';
import { mapState } from 'vuex';

export default {
  name: 'RemoveMemberButton',
  components: { GlButton },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  inject: ['namespace'],
  props: {
    memberId: {
      type: Number,
      required: true,
    },
    memberType: {
      type: String,
      required: false,
      default: null,
    },
    message: {
      type: String,
      required: true,
    },
    title: {
      type: String,
      required: true,
    },
    icon: {
      type: String,
      required: false,
      default: 'remove',
    },
    isAccessRequest: {
      type: Boolean,
      required: false,
      default: false,
    },
    isInvite: {
      type: Boolean,
      required: false,
      default: false,
    },
    oncallSchedules: {
      type: Object,
      required: false,
      default: () => {},
    },
  },
  computed: {
    ...mapState({
      memberPath(state) {
        return state[this.namespace].memberPath;
      },
    }),
    computedMemberPath() {
      return this.memberPath.replace(':id', this.memberId);
    },
    stringifiedSchedules() {
      return JSON.stringify(this.oncallSchedules);
    },
  },
};
</script>

<template>
  <gl-button
    v-gl-tooltip.hover
    class="js-remove-member-button"
    variant="danger"
    :title="title"
    :aria-label="title"
    :icon="icon"
    :data-member-path="computedMemberPath"
    :data-member-type="memberType"
    :data-is-access-request="isAccessRequest"
    :data-is-invite="isInvite"
    :data-message="message"
    :data-oncall-schedules="stringifiedSchedules"
    data-qa-selector="delete_member_button"
  />
</template>

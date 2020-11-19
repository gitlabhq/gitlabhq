<script>
import { mapState } from 'vuex';
import { GlButton, GlTooltipDirective } from '@gitlab/ui';

export default {
  name: 'RemoveMemberButton',
  components: { GlButton },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    memberId: {
      type: Number,
      required: true,
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
  },
  computed: {
    ...mapState(['memberPath']),
    computedMemberPath() {
      return this.memberPath.replace(':id', this.memberId);
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
    :data-is-access-request="isAccessRequest"
    :data-message="message"
    data-qa-selector="delete_member_button"
  />
</template>

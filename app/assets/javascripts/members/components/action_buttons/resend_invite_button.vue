<script>
import { GlButton, GlTooltipDirective } from '@gitlab/ui';
// eslint-disable-next-line no-restricted-imports
import { mapState } from 'vuex';
import csrf from '~/lib/utils/csrf';
import { __ } from '~/locale';

export default {
  name: 'ResendInviteButton',
  csrf,
  title: __('Resend invite'),
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
  },
  computed: {
    ...mapState({
      memberPath(state) {
        return state[this.namespace].memberPath;
      },
    }),
    resendPath() {
      return this.memberPath.replace(/:id$/, `${this.memberId}/resend_invite`);
    },
  },
};
</script>

<template>
  <form :action="resendPath" method="post">
    <input :value="$options.csrf.token" type="hidden" name="authenticity_token" />
    <gl-button
      v-gl-tooltip.hover
      :title="$options.title"
      :aria-label="$options.title"
      icon="paper-airplane"
      type="submit"
    />
  </form>
</template>

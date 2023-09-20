<script>
import { GlButton, GlForm, GlTooltipDirective } from '@gitlab/ui';
// eslint-disable-next-line no-restricted-imports
import { mapState } from 'vuex';
import csrf from '~/lib/utils/csrf';
import { __ } from '~/locale';

export default {
  name: 'ApproveAccessRequestButton',
  csrf,
  title: __('Grant access'),
  components: { GlButton, GlForm },
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
    approvePath() {
      return this.memberPath.replace(/:id$/, `${this.memberId}/approve_access_request`);
    },
  },
};
</script>

<template>
  <gl-form :action="approvePath" method="post">
    <input :value="$options.csrf.token" type="hidden" name="authenticity_token" />
    <gl-button
      v-gl-tooltip.hover
      :title="$options.title"
      :aria-label="$options.title"
      data-testid="approve-access-request-button"
      icon="check"
      type="submit"
    />
  </gl-form>
</template>

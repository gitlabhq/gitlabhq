<script>
import { GlButton, GlIcon, GlButtonGroup, GlTooltipDirective } from '@gitlab/ui';
import { __ } from '~/locale';

const IGNORED = 'ignored';
const RESOLVED = 'resolved';
const UNRESOLVED = 'unresolved';

const statusValidation = [IGNORED, RESOLVED, UNRESOLVED];

export default {
  components: {
    GlButton,
    GlIcon,
    GlButtonGroup,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    error: {
      type: Object,
      required: true,
      validator: ({ status }) => statusValidation.includes(status),
    },
  },
  computed: {
    ignoreBtn() {
      return this.error.status !== IGNORED
        ? { status: IGNORED, icon: 'eye-slash', title: __('Ignore') }
        : { status: UNRESOLVED, icon: 'eye', title: __('Undo Ignore') };
    },
    resolveBtn() {
      return this.error.status !== RESOLVED
        ? { status: RESOLVED, icon: 'check-circle', title: __('Resolve') }
        : { status: UNRESOLVED, icon: 'canceled-circle', title: __('Unresolve') };
    },
    detailsLink() {
      return `error_tracking/${this.error.id}/details`;
    },
  },
};
</script>

<template>
  <div>
    <gl-button-group class="gl-flex-direction-column flex-md-row gl-ml-0 ml-md-n4">
      <gl-button
        :key="ignoreBtn.status"
        :ref="`${ignoreBtn.title.toLowerCase()}Error`"
        v-gl-tooltip.hover
        class="gl-display-block gl-mb-4 mb-md-0 gl-w-full"
        :title="ignoreBtn.title"
        :aria-label="ignoreBtn.title"
        @click="$emit('update-issue-status', { errorId: error.id, status: ignoreBtn.status })"
      >
        <gl-icon class="gl-display-none d-md-inline gl-m-0" :name="ignoreBtn.icon" :size="12" />
        <span class="d-md-none">{{ ignoreBtn.title }}</span>
      </gl-button>
      <gl-button
        :key="resolveBtn.status"
        :ref="`${resolveBtn.title.toLowerCase()}Error`"
        v-gl-tooltip.hover
        class="gl-display-block gl-mb-4 mb-md-0 gl-w-full"
        :title="resolveBtn.title"
        :aria-label="resolveBtn.title"
        @click="$emit('update-issue-status', { errorId: error.id, status: resolveBtn.status })"
      >
        <gl-icon class="gl-display-none d-md-inline gl-m-0" :name="resolveBtn.icon" :size="12" />
        <span class="d-md-none">{{ resolveBtn.title }}</span>
      </gl-button>
    </gl-button-group>
    <gl-button
      :href="detailsLink"
      category="primary"
      variant="info"
      class="gl-display-block d-md-none gl-mb-4 mb-md-0"
    >
      {{ __('More details') }}
    </gl-button>
  </div>
</template>

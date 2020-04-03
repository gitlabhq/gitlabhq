<script>
import { GlDeprecatedButton, GlIcon, GlButtonGroup, GlTooltipDirective } from '@gitlab/ui';
import { __ } from '~/locale';

const IGNORED = 'ignored';
const RESOLVED = 'resolved';
const UNRESOLVED = 'unresolved';

const statusValidation = [IGNORED, RESOLVED, UNRESOLVED];

export default {
  components: {
    GlDeprecatedButton,
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
    <gl-button-group class="flex-column flex-md-row ml-0 ml-md-n4">
      <gl-deprecated-button
        :key="ignoreBtn.status"
        :ref="`${ignoreBtn.title.toLowerCase()}Error`"
        v-gl-tooltip.hover
        class="d-block mb-2 mb-md-0 w-100"
        :title="ignoreBtn.title"
        @click="$emit('update-issue-status', { errorId: error.id, status: ignoreBtn.status })"
      >
        <gl-icon class="d-none d-md-inline m-0" :name="ignoreBtn.icon" :size="12" />
        <span class="d-md-none">{{ ignoreBtn.title }}</span>
      </gl-deprecated-button>
      <gl-deprecated-button
        :key="resolveBtn.status"
        :ref="`${resolveBtn.title.toLowerCase()}Error`"
        v-gl-tooltip.hover
        class="d-block mb-2 mb-md-0 w-100"
        :title="resolveBtn.title"
        @click="$emit('update-issue-status', { errorId: error.id, status: resolveBtn.status })"
      >
        <gl-icon class="d-none d-md-inline m-0" :name="resolveBtn.icon" :size="12" />
        <span class="d-md-none">{{ resolveBtn.title }}</span>
      </gl-deprecated-button>
    </gl-button-group>
    <gl-deprecated-button
      :href="detailsLink"
      category="secondary"
      variant="info"
      class="d-block d-md-none mb-2 mb-md-0"
    >
      {{ __('More details') }}
    </gl-deprecated-button>
  </div>
</template>

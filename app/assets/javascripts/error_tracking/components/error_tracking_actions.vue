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
    <gl-button-group class="-gl-ml-6 gl-flex-col md:gl-flex-row">
      <gl-button
        :key="ignoreBtn.status"
        :ref="`${ignoreBtn.title.toLowerCase()}Error`"
        v-gl-tooltip.hover
        class="gl-mb-4 gl-block gl-w-full md:gl-mb-0"
        :title="ignoreBtn.title"
        :aria-label="ignoreBtn.title"
        @click="$emit('update-issue-status', { errorId: error.id, status: ignoreBtn.status })"
      >
        <gl-icon class="gl-m-0 gl-hidden md:gl-inline" :name="ignoreBtn.icon" :size="12" />
        <span class="md:gl-hidden">{{ ignoreBtn.title }}</span>
      </gl-button>
      <gl-button
        :key="resolveBtn.status"
        :ref="`${resolveBtn.title.toLowerCase()}Error`"
        v-gl-tooltip.hover
        class="gl-mb-4 gl-block gl-w-full md:gl-mb-0"
        :title="resolveBtn.title"
        :aria-label="resolveBtn.title"
        @click="$emit('update-issue-status', { errorId: error.id, status: resolveBtn.status })"
      >
        <gl-icon class="gl-m-0 gl-hidden md:gl-inline" :name="resolveBtn.icon" :size="12" />
        <span class="md:gl-hidden">{{ resolveBtn.title }}</span>
      </gl-button>
    </gl-button-group>
    <gl-button
      :href="detailsLink"
      category="primary"
      variant="confirm"
      class="gl-mb-4 gl-block md:gl-mb-0 md:!gl-hidden"
    >
      {{ __('More details') }}
    </gl-button>
  </div>
</template>

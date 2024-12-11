<script>
import { GlButton, GlButtonGroup, GlTooltipDirective } from '@gitlab/ui';
import { __ } from '~/locale';

const IGNORED = 'ignored';
const RESOLVED = 'resolved';
const UNRESOLVED = 'unresolved';

const statusValidation = [IGNORED, RESOLVED, UNRESOLVED];

export default {
  components: {
    GlButton,

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
  <div class="gl-flex md:gl-justify-end">
    <gl-button-group class="gl-hidden md:gl-flex">
      <gl-button
        :key="ignoreBtn.status"
        :ref="`${ignoreBtn.title.toLowerCase()}Error`"
        v-gl-tooltip.hover
        class="gl-mb-0 gl-block gl-w-full"
        :title="ignoreBtn.title"
        :aria-label="ignoreBtn.title"
        :icon="ignoreBtn.icon"
        @click="$emit('update-issue-status', { errorId: error.id, status: ignoreBtn.status })"
      />
      <gl-button
        :key="resolveBtn.status"
        :ref="`${resolveBtn.title.toLowerCase()}Error`"
        v-gl-tooltip.hover
        class="gl-mb-0 gl-block gl-w-full"
        :icon="resolveBtn.icon"
        :title="resolveBtn.title"
        :aria-label="resolveBtn.title"
        @click="$emit('update-issue-status', { errorId: error.id, status: resolveBtn.status })"
      />
    </gl-button-group>
    <div class="gl-flex gl-gap-3 md:gl-hidden">
      <gl-button
        :key="ignoreBtn.status"
        :ref="`${ignoreBtn.title.toLowerCase()}Error`"
        v-gl-tooltip.hover
        class="gl-mb-0"
        :title="ignoreBtn.title"
        :aria-label="ignoreBtn.title"
        @click="$emit('update-issue-status', { errorId: error.id, status: ignoreBtn.status })"
      >
        {{ ignoreBtn.title }}
      </gl-button>
      <gl-button
        :key="resolveBtn.status"
        :ref="`${resolveBtn.title.toLowerCase()}Error`"
        v-gl-tooltip.hover
        class="gl-mb-0"
        :title="resolveBtn.title"
        :aria-label="resolveBtn.title"
        @click="$emit('update-issue-status', { errorId: error.id, status: resolveBtn.status })"
      >
        {{ resolveBtn.title }}
      </gl-button>
    </div>
    <gl-button
      :href="detailsLink"
      category="primary"
      variant="confirm"
      class="gl-mb-0 gl-ml-3 md:!gl-hidden"
    >
      {{ __('More details') }}
    </gl-button>
  </div>
</template>

<script>
import { GlButton, GlAlert, GlModalDirective } from '@gitlab/ui';
import { CENTERED_LIMITED_CONTAINER_CLASSES } from '../constants';

export default {
  components: {
    GlAlert,
    GlButton,
  },
  directives: {
    GlModalDirective,
  },
  props: {
    limited: {
      type: Boolean,
      required: true,
    },
    mergeable: {
      type: Boolean,
      required: true,
    },
    resolutionPath: {
      type: String,
      required: true,
    },
  },
  computed: {
    containerClasses() {
      return {
        [CENTERED_LIMITED_CONTAINER_CLASSES]: this.limited,
      };
    },
  },
};
</script>

<template>
  <div :class="containerClasses">
    <gl-alert
      :dismissible="false"
      :title="__('There are merge conflicts')"
      variant="warning"
      class="gl-mb-5"
    >
      <p class="gl-mb-2">
        {{ __('The comparison view may be inaccurate due to merge conflicts.') }}
      </p>
      <p class="gl-mb-0">
        {{
          __(
            'Resolve these conflicts or ask someone with write access to this repository to merge it locally.',
          )
        }}
      </p>
      <template #actions>
        <gl-button
          v-if="resolutionPath"
          :href="resolutionPath"
          variant="info"
          class="gl-mr-5 gl-alert-action"
        >
          {{ __('Resolve conflicts') }}
        </gl-button>
        <gl-button
          v-if="mergeable"
          v-gl-modal-directive="'modal-merge-info'"
          class="gl-alert-action"
        >
          {{ __('Merge locally') }}
        </gl-button>
      </template>
    </gl-alert>
  </div>
</template>

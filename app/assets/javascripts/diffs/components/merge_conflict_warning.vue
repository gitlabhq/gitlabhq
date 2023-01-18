<script>
import { GlButton, GlAlert, GlModalDirective } from '@gitlab/ui';

export default {
  components: {
    GlAlert,
    GlButton,
  },
  directives: {
    GlModalDirective,
  },
  props: {
    mergeable: {
      type: Boolean,
      required: true,
    },
    resolutionPath: {
      type: String,
      required: true,
    },
  },
};
</script>

<template>
  <div>
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
            'Resolve these conflicts, or ask someone with write access to this repository to resolve them locally.',
          )
        }}
      </p>
      <template #actions>
        <gl-button
          v-if="resolutionPath"
          :href="resolutionPath"
          variant="confirm"
          class="gl-mr-3 gl-alert-action"
        >
          {{ __('Resolve conflicts') }}
        </gl-button>
        <gl-button
          v-if="mergeable"
          v-gl-modal-directive="'modal-merge-info'"
          class="gl-alert-action"
        >
          {{ __('Resolve locally') }}
        </gl-button>
      </template>
    </gl-alert>
  </div>
</template>

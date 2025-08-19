<script>
import { GlSprintf, GlFormGroup } from '@gitlab/ui';

export default {
  components: {
    GlFormGroup,
    GlSprintf,
  },
  props: {
    label: {
      type: String,
      required: false,
      default: null,
    },
    labelFor: {
      type: String,
      required: false,
      default: null,
    },
    helpPath: {
      type: String,
      required: false,
      default: null,
    },
    helpText: {
      type: String,
      required: false,
      default: null,
    },
    locked: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  placeholders: {
    em: { em: ['em_start', 'em_end'] },
  },
};
</script>

<template>
  <gl-form-group :label-for="labelFor" label-class="!gl-pb-1" class="project-feature-row gl-mb-0">
    <template #label>
      <span
        v-if="label"
        :class="{ 'gl-text-disabled': locked }"
        data-testid="project-settings-row-label"
      >
        {{ label }}
      </span>
      <slot name="label-icon"></slot>
    </template>

    <div>
      <span v-if="helpText" class="gl-text-subtle" data-testid="project-settings-row-help-text">
        <gl-sprintf :message="helpText" :placeholders="$options.placeholders.em">
          <template #em="{ content }">
            <em>{{ content }}</em>
          </template>
        </gl-sprintf>
      </span>
      <span v-if="helpPath"
        ><a :href="helpPath" target="_blank">{{ __('Learn more') }}</a
        >.</span
      >
      <slot v-else name="help-link"></slot>
    </div>
    <slot></slot>
  </gl-form-group>
</template>

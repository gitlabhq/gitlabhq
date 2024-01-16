<script>
import { GlFormGroup, GlFormInput } from '@gitlab/ui';
import { __ } from '~/locale';

export default {
  components: {
    GlFormGroup,
    GlFormInput,
  },
  i18n: {
    titleLabel: __('Title (required)'),
  },
  props: {
    title: {
      type: String,
      required: true,
    },
    isEditing: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
};
</script>

<template>
  <gl-form-group v-if="isEditing" :label="$options.i18n.titleLabel" label-for="work-item-title">
    <gl-form-input
      class="gl-w-full"
      :value="title"
      data-testid="work-item-title-with-edit"
      @keydown.meta.enter="$emit('updateWorkItem')"
      @keydown.ctrl.enter="$emit('updateWorkItem')"
      @input="$emit('updateDraft', $event)"
    />
  </gl-form-group>
  <h1
    v-else
    data-testid="work-item-title"
    class="gl-w-full gl-font-weight-normal gl-sm-font-weight-bold gl-mb-1 gl-mt-0 gl-font-size-h-display"
  >
    {{ title }}
  </h1>
</template>

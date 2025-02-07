<script>
import { uniqueId } from 'lodash';
import { GlFormGroup, GlFormInput } from '@gitlab/ui';
import { __ } from '~/locale';

export default {
  components: {
    GlFormGroup,
    GlFormInput,
  },
  i18n: {
    titleLabel: __('Title (required)'),
    requiredFieldFeedback: __('A title is required'),
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
    isModal: {
      type: Boolean,
      required: false,
      default: false,
    },
    isValid: {
      type: Boolean,
      required: false,
      default: true,
    },
  },
  data() {
    return {
      inputId: uniqueId('work-item-title-'),
    };
  },
};
</script>

<template>
  <gl-form-group
    v-if="isEditing"
    :label="$options.i18n.titleLabel"
    :label-for="inputId"
    :invalid-feedback="$options.i18n.requiredFieldFeedback"
    :state="isValid"
  >
    <gl-form-input
      :id="inputId"
      class="gl-w-full"
      :value="title"
      :state="isValid"
      autofocus
      data-testid="work-item-title-input"
      @keydown.meta.enter="$emit('updateWorkItem')"
      @keydown.ctrl.enter="$emit('updateWorkItem')"
      @input="$emit('updateDraft', $event)"
    />
  </gl-form-group>
  <component
    :is="isModal ? 'h2' : 'h1'"
    v-else
    data-testid="work-item-title"
    class="gl-heading-1 !gl-m-0 gl-w-full"
  >
    {{ title }}
  </component>
</template>

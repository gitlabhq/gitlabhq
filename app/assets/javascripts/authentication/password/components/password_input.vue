<script>
import { GlFormInput, GlButton, GlTooltipDirective } from '@gitlab/ui';
import { SHOW_PASSWORD, HIDE_PASSWORD } from '../constants';

export default {
  name: 'PasswordInput',
  components: {
    GlFormInput,
    GlButton,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    title: {
      type: String,
      required: false,
      default: null,
    },
    id: {
      type: String,
      required: false,
      default: null,
    },
    minimumPasswordLength: {
      type: String,
      required: false,
      default: null,
    },
    testid: {
      type: String,
      required: false,
      default: null,
    },
    trackActionForErrors: {
      type: String,
      required: false,
      default: null,
    },
    autocomplete: {
      type: String,
      required: false,
      default: 'current-password',
    },
    autofocus: {
      type: Boolean,
      required: false,
      default: false,
    },
    required: {
      type: Boolean,
      required: false,
      default: true,
    },
    name: {
      type: String,
      required: true,
    },
    disabled: {
      type: Boolean,
      required: false,
      default: false,
    },
    state: {
      type: Boolean,
      required: false,
      default: null,
    },
    /**
     * Can be used for v-model on this component
     */
    value: {
      type: String,
      required: false,
      default: null,
    },
  },
  data() {
    return {
      isMasked: true,
    };
  },
  computed: {
    type() {
      return this.isMasked ? 'password' : 'text';
    },
    toggleVisibilityLabel() {
      return this.isMasked ? SHOW_PASSWORD : HIDE_PASSWORD;
    },
    toggleVisibilityIcon() {
      return this.isMasked ? 'eye' : 'eye-slash';
    },
  },
  methods: {
    handleToggleVisibilityButtonClick() {
      this.isMasked = !this.isMasked;
    },
  },
};
</script>

<template>
  <div class="gl-field-error-anchor gl-relative">
    <gl-form-input
      :id="id"
      :value="value"
      class="js-password-complexity-validation js-track-error !gl-pr-8"
      :required="required"
      :autocomplete="autocomplete"
      :autofocus="autofocus"
      :name="name"
      :minlength="minimumPasswordLength"
      :data-testid="testid"
      :data-track-action-for-errors="trackActionForErrors"
      :title="title"
      :type="type"
      :disabled="disabled"
      :state="state"
      v-on="$listeners"
    />
    <gl-button
      v-gl-tooltip="toggleVisibilityLabel"
      class="gl-absolute gl-right-0 gl-top-0"
      category="tertiary"
      :aria-label="toggleVisibilityLabel"
      :icon="toggleVisibilityIcon"
      :disabled="disabled"
      @click="handleToggleVisibilityButtonClick"
    />
  </div>
</template>

<style scoped>
/*
 * Hiding the browser's native password reveal control when showing our own toggle.
 * Avoids duplicate eye icons in Microsoft Edge (and IE), which only show their
 * reveal button when the field is focused and has content.
 */
:deep(input[type='password']::-ms-reveal) {
  display: none;
}
</style>

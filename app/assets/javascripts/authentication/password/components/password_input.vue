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
    required: {
      type: Boolean,
      required: false,
      default: true,
    },
    name: {
      type: String,
      required: true,
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
      class="js-password-complexity-validation js-track-error !gl-pr-8"
      :required="required"
      :autocomplete="autocomplete"
      :name="name"
      :minlength="minimumPasswordLength"
      :data-testid="testid"
      :data-track-action-for-errors="trackActionForErrors"
      :title="title"
      :type="type"
    />
    <gl-button
      v-gl-tooltip="toggleVisibilityLabel"
      class="gl-absolute gl-right-0 gl-top-0"
      category="tertiary"
      :aria-label="toggleVisibilityLabel"
      :icon="toggleVisibilityIcon"
      @click="handleToggleVisibilityButtonClick"
    />
  </div>
</template>

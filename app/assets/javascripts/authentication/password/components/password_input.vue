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
      default: '',
    },
    id: {
      type: String,
      required: false,
      default: '',
    },
    minimumPasswordLength: {
      type: String,
      required: false,
      default: '',
    },
    qaSelector: {
      type: String,
      required: false,
      default: '',
    },
    autocomplete: {
      type: String,
      required: false,
      default: 'current-password',
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
  <div class="gl-field-error-anchor input-icon-wrapper">
    <gl-form-input
      :id="id"
      class="js-password-complexity-validation gl-pr-8!"
      required
      :autocomplete="autocomplete"
      :name="name"
      :minlength="minimumPasswordLength"
      :data-qa-selector="qaSelector"
      :title="title"
      :type="type"
    />
    <gl-button
      v-gl-tooltip="toggleVisibilityLabel"
      class="input-icon-right gl-right-0!"
      category="tertiary"
      :aria-label="toggleVisibilityLabel"
      :icon="toggleVisibilityIcon"
      @click="handleToggleVisibilityButtonClick"
    />
  </div>
</template>

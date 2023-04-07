<script>
import { GlFormInput, GlButton, GlTooltipDirective } from '@gitlab/ui';
import { sprintf } from '~/locale';
import { SHOW_PASSWORD, HIDE_PASSWORD, PASSWORD_TITLE } from '../constants';

export default {
  name: 'PasswordInput',
  i18n: {
    showPassword: SHOW_PASSWORD,
    hidePassword: HIDE_PASSWORD,
  },
  components: {
    GlFormInput,
    GlButton,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    resourceName: {
      type: String,
      required: true,
    },
    minimumPasswordLength: {
      type: String,
      required: true,
    },
    qaSelector: {
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
    passwordTitle() {
      return sprintf(PASSWORD_TITLE, { minimum_password_length: this.minimumPasswordLength });
    },
    type() {
      return this.isMasked ? 'password' : 'text';
    },
    toggleVisibilityLabel() {
      return this.isMasked ? this.$options.i18n.showPassword : this.$options.i18n.hidePassword;
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
      :id="`${resourceName}_password`"
      class="js-password-complexity-validation gl-pr-8!"
      required
      autocomplete="new-password"
      :name="`${resourceName}[password]`"
      :minlength="minimumPasswordLength"
      :data-qa-selector="qaSelector"
      :title="passwordTitle"
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

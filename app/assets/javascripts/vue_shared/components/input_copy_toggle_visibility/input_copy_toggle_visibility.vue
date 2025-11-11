<script>
import {
  GlFormInputGroup,
  GlFormInput,
  GlFormGroup,
  GlButtonGroup,
  GlButton,
  GlTooltipDirective,
} from '@gitlab/ui';

import { __ } from '~/locale';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import { copyToClipboard } from '~/lib/utils/copy_to_clipboard';
import { Mousetrap, MOUSETRAP_COPY_KEYBOARD_SHORTCUT } from '~/lib/mousetrap';
import SimpleCopyButton from '~/vue_shared/components/simple_copy_button.vue';

export default {
  name: 'InputCopyToggleVisibility',
  i18n: {
    toggleVisibilityLabelHide: __('Click to hide'),
    toggleVisibilityLabelReveal: __('Click to reveal'),
  },
  components: {
    GlFormInputGroup,
    GlFormInput,
    GlFormGroup,
    GlButtonGroup,
    GlButton,
    SimpleCopyButton,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    value: {
      type: String,
      required: false,
      default: '',
    },
    initialVisibility: {
      type: Boolean,
      required: false,
      default: false,
    },
    showToggleVisibilityButton: {
      type: Boolean,
      required: false,
      default: true,
    },
    showCopyButton: {
      type: Boolean,
      required: false,
      default: true,
    },
    copyButtonTitle: {
      type: String,
      required: false,
      default: __('Copy'),
    },
    copyButtonToastMessage: {
      type: [String, Boolean],
      required: false,
      default: __('Copied to clipboard.'),
    },
    readonly: {
      type: Boolean,
      required: false,
      default: false,
    },
    formInputGroupProps: {
      type: Object,
      required: false,
      default() {
        return {};
      },
    },
    size: {
      type: String,
      required: false,
      default: null,
    },
  },
  data() {
    if (!this.readonly && !this.value) {
      return {
        valueIsVisible: true,
      };
    }

    return {
      valueIsVisible: this.initialVisibility,
      mousetrap: null,
    };
  },
  computed: {
    toggleVisibilityLabel() {
      return this.valueIsVisible
        ? this.$options.i18n.toggleVisibilityLabelHide
        : this.$options.i18n.toggleVisibilityLabelReveal;
    },
    toggleVisibilityIcon() {
      return this.valueIsVisible ? 'eye-slash' : 'eye';
    },
    computedValueIsVisible() {
      return !this.showToggleVisibilityButton || this.valueIsVisible;
    },
    formInputClass() {
      return [
        '!gl-font-monospace !gl-cursor-default',
        { 'input-copy-show-disc': !this.computedValueIsVisible },
        this.formInputGroupProps.class,
      ];
    },
    invalidFeedbackIsVisible() {
      const hasFeedback = Boolean(this.$attrs['invalid-feedback']);
      return this.formInputGroupProps?.state === false && hasFeedback;
    },
  },
  mounted() {
    this.mousetrap = new Mousetrap(this.$refs.input.$el);
    this.mousetrap.bind(MOUSETRAP_COPY_KEYBOARD_SHORTCUT, this.handleKeyboardCopy);
  },
  beforeDestroy() {
    this.mousetrap?.unbind(MOUSETRAP_COPY_KEYBOARD_SHORTCUT);
  },

  methods: {
    handleToggleVisibilityButtonClick() {
      this.valueIsVisible = !this.valueIsVisible;

      this.$emit('visibility-change', this.valueIsVisible);
    },
    async handleClick() {
      if (this.readonly) {
        this.$refs.input.$el.select();
      } else if (!this.valueIsVisible) {
        const { selectionStart, selectionEnd } = this.$refs.input.$el;
        this.handleToggleVisibilityButtonClick();

        setTimeout(() => {
          // When the input type is changed from 'password'' to 'text', cursor position is reset in some browsers.
          // This makes clicking to edit difficult due to typing in unexpected location, so we preserve the cursor position / selection
          this.$refs.input.$el.setSelectionRange(selectionStart, selectionEnd);
        }, 0);
      }
    },
    async handleKeyboardCopy(e) {
      if (this.computedValueIsVisible) {
        // Value will be copied by native browser behavior
        return;
      }

      // Prevent copying masked version
      e.preventDefault?.();
      try {
        // User is trying to copy from the password input, set their clipboard for them.
        // No toast?: We don't show a toast notification, as that is not an usual keyboard behavior
        await copyToClipboard(this.value);
      } catch (error) {
        Sentry.captureException(error);
      }
    },
    handleInput(newValue) {
      this.$emit('input', newValue);
    },
  },
};
</script>
<template>
  <gl-form-group
    v-bind="$attrs"
    :class="{ 'input-copy-toggle-visibility-is-invalid': invalidFeedbackIsVisible }"
  >
    <gl-form-input-group>
      <gl-form-input
        ref="input"
        :readonly="readonly"
        :width="size"
        :class="formInputClass"
        v-bind="formInputGroupProps"
        :value="value"
        class="!gl-border !gl-border-r-section"
        @input="handleInput"
        @click="handleClick"
      />

      <!--
        This v-if is necessary to avoid an issue with border radius.
        See https://gitlab.com/gitlab-org/gitlab/-/merge_requests/88059#note_969812649
       -->
      <template v-if="showToggleVisibilityButton || showCopyButton" #append>
        <gl-button-group>
          <gl-button
            v-if="showToggleVisibilityButton"
            v-gl-tooltip.hover="toggleVisibilityLabel"
            :aria-label="toggleVisibilityLabel"
            :icon="toggleVisibilityIcon"
            data-testid="toggle-visibility-button"
            @click.stop="handleToggleVisibilityButtonClick"
          />
          <simple-copy-button
            v-if="showCopyButton"
            :text="value"
            :title="copyButtonTitle"
            :toast-message="copyButtonToastMessage"
          />
        </gl-button-group>
      </template>
    </gl-form-input-group>
    <!-- eslint-disable-next-line @gitlab/vue-prefer-dollar-scopedslots -->
    <template v-for="slot in Object.keys($slots)" #[slot]>
      <slot :name="slot"></slot>
    </template>
  </gl-form-group>
</template>
<style>
.input-copy-show-disc {
  -webkit-text-security: disc;
}
/*
  Bootstrap's invalid feedback displays based on a sibling selector which is incompatible with form-input-group.
  So we must manually force the feedback to display when the input is invalid. See: https://github.com/bootstrap-vue/bootstrap-vue/issues/1251
 */
.input-copy-toggle-visibility-is-invalid .invalid-feedback {
  display: block;
}
</style>

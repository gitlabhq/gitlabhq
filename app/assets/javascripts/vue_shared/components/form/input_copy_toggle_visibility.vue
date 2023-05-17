<script>
import {
  GlFormInputGroup,
  GlFormInput,
  GlFormGroup,
  GlButton,
  GlTooltipDirective,
} from '@gitlab/ui';

import { __ } from '~/locale';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';

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
    GlButton,
    ClipboardButton,
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
    formInputGroupProps: {
      type: Object,
      required: false,
      default() {
        return {};
      },
    },
  },
  data() {
    return {
      valueIsVisible: this.initialVisibility,
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
    displayedValue() {
      return this.computedValueIsVisible ? this.value : '*'.repeat(this.value.length || 20);
    },
  },
  methods: {
    handleToggleVisibilityButtonClick() {
      this.valueIsVisible = !this.valueIsVisible;

      this.$emit('visibility-change', this.valueIsVisible);
    },
    handleClick() {
      this.$refs.input.$el.select();
    },
    handleCopyButtonClick() {
      this.$emit('copy');
    },
    handleFormInputCopy(event) {
      this.handleCopyButtonClick();

      if (this.computedValueIsVisible) {
        return;
      }

      event.clipboardData.setData('text/plain', this.value);
      event.preventDefault();
    },
  },
};
</script>
<template>
  <gl-form-group v-bind="$attrs">
    <gl-form-input-group>
      <gl-form-input
        ref="input"
        readonly
        class="gl-font-monospace! gl-cursor-default!"
        v-bind="formInputGroupProps"
        :value="displayedValue"
        @copy="handleFormInputCopy"
        @click="handleClick"
      />

      <!--
        This v-if is necessary to avoid an issue with border radius.
        See https://gitlab.com/gitlab-org/gitlab/-/merge_requests/88059#note_969812649
       -->
      <template v-if="showToggleVisibilityButton || showCopyButton" #append>
        <gl-button
          v-if="showToggleVisibilityButton"
          v-gl-tooltip.hover="toggleVisibilityLabel"
          :aria-label="toggleVisibilityLabel"
          :icon="toggleVisibilityIcon"
          data-testid="toggle-visibility-button"
          data-qa-selector="toggle_visibility_button"
          @click.stop="handleToggleVisibilityButtonClick"
        />
        <clipboard-button
          v-if="showCopyButton"
          :text="value"
          :title="copyButtonTitle"
          data-qa-selector="clipboard_button"
          @click="handleCopyButtonClick"
        />
      </template>
    </gl-form-input-group>
    <!-- eslint-disable-next-line @gitlab/vue-prefer-dollar-scopedslots -->
    <template v-for="slot in Object.keys($slots)" #[slot]>
      <slot :name="slot"></slot>
    </template>
  </gl-form-group>
</template>

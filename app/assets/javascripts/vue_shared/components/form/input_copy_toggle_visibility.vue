<script>
import { GlFormInputGroup, GlFormGroup, GlButton, GlTooltipDirective } from '@gitlab/ui';

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
    handleCopyButtonClick() {
      this.$emit('copy');
    },
    handleFormInputCopy(event) {
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
    <gl-form-input-group
      :value="displayedValue"
      input-class="gl-font-monospace! gl-cursor-default!"
      select-on-click
      readonly
      v-bind="formInputGroupProps"
      @copy="handleFormInputCopy"
    >
      <template v-if="showToggleVisibilityButton || showCopyButton" #append>
        <gl-button
          v-if="showToggleVisibilityButton"
          v-gl-tooltip.hover="toggleVisibilityLabel"
          :aria-label="toggleVisibilityLabel"
          :icon="toggleVisibilityIcon"
          @click="handleToggleVisibilityButtonClick"
        />
        <clipboard-button
          v-if="showCopyButton"
          :text="value"
          :title="copyButtonTitle"
          @click="handleCopyButtonClick"
        />
      </template>
    </gl-form-input-group>
    <template v-for="slot in Object.keys($slots)" #[slot]>
      <slot :name="slot"></slot>
    </template>
  </gl-form-group>
</template>

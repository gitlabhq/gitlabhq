<!--
  this component should be here only temporary until this MR gets sorted:
  https://gitlab.com/gitlab-org/gitlab-ui/-/merge_requests/3969
 -->
<script>
import { GlFormInput, GlIcon, GlLoadingIcon, GlButton, GlTooltipDirective } from '@gitlab/ui';
import { __ } from '~/locale';
import GlClearIconButton from './clear_icon_button.vue';

export default {
  name: 'GlSearchBoxByType',
  components: {
    GlClearIconButton,
    GlIcon,
    GlFormInput,
    GlLoadingIcon,
    GlButton,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  inheritAttrs: false,
  model: {
    prop: 'value',
    event: 'input',
  },
  props: {
    /**
     * If provided, used as value of search input
     */
    value: {
      type: String,
      required: false,
      default: '',
    },
    borderless: {
      type: Boolean,
      required: false,
      default: false,
    },
    clearButtonTitle: {
      type: String,
      required: false,
      default: () => __('Clear'),
    },
    /**
     * If provided and true, disables the input and controls
     */
    disabled: {
      type: Boolean,
      required: false,
      default: false,
    },
    /**
     * Puts search box into loading state, rendering spinner
     */
    isLoading: {
      type: Boolean,
      required: false,
      default: false,
    },
    /**
     * Container for tooltip. Valid values: DOM node, selector string or `false` for default
     */
    tooltipContainer: {
      required: false,
      default: false,
      validator: (value) =>
        value === false || typeof value === 'string' || value instanceof HTMLElement,
    },
    regexButtonIsVisible: {
      type: Boolean,
      required: false,
      default: false,
    },
    regexButtonState: {
      type: Boolean,
      required: false,
      default: false,
    },
    regexButtonHandler: {
      type: Function,
      required: false,
      default: () => {},
    },
  },
  i18n: {
    label: __('Use Regular Expression'),
  },
  computed: {
    inputAttributes() {
      const attributes = {
        type: 'search',
        placeholder: __('Search'),
        ...this.$attrs,
      };

      if (!attributes['aria-label']) {
        attributes['aria-label'] = attributes.placeholder;
      }

      return attributes;
    },
    hasValue() {
      return Boolean(this.value.length);
    },
    inputListeners() {
      return {
        ...this.$listeners,
        input: this.onInput,
        focusin: this.onFocusin,
        focusout: this.onFocusout,
      };
    },
    showClearButton() {
      return this.hasValue && !this.disabled;
    },
    regexButtonHighlightClass() {
      return {
        '!gl-bg-blue-50': this.regexButtonState,
        '!gl-shadow-none': !this.regexButtonState,
      };
    },
  },
  methods: {
    isInputOrClearButton(element) {
      return element === this.$refs.input?.$el || element === this.$refs.clearButton?.$el;
    },
    clearInput() {
      this.onInput('');
      this.focusInput();
    },
    focusInput() {
      this.$refs.input.$el.focus();
    },
    onInput(value) {
      this.$emit('input', value);
    },
    onFocusout(event) {
      const { relatedTarget } = event;

      if (this.isInputOrClearButton(relatedTarget)) {
        return;
      }

      this.$emit('focusout', event);
    },
    onFocusin(event) {
      const { relatedTarget } = event;

      if (this.isInputOrClearButton(relatedTarget)) {
        return;
      }

      this.$emit('focusin', event);
    },
  },
};
</script>

<template>
  <div class="gl-search-box-by-type">
    <gl-icon name="search" class="gl-search-box-by-type-search-icon" />
    <gl-form-input
      ref="input"
      :value="value"
      :disabled="disabled"
      :class="{
        'gl-search-box-by-type-input': !borderless,
        'gl-search-box-by-type-input-borderless': borderless,
      }"
      v-bind="inputAttributes"
      v-on="inputListeners"
    />
    <div class="gl-search-box-by-type-right-icons">
      <div v-if="isLoading || showClearButton">
        <gl-loading-icon v-if="isLoading" class="gl-search-box-by-type-loading-icon" />
        <gl-clear-icon-button
          v-if="showClearButton"
          ref="clearButton"
          :title="clearButtonTitle"
          :tooltip-container="tooltipContainer"
          class="gl-search-box-by-type-clear gl-clear-icon-button"
          @click.stop="clearInput"
          @focusin="onFocusin"
          @focusout="onFocusout"
        />
      </div>
      <!-- @slot Items are placed between right edge and clear button. -->
      <div class="gl-ml-1 gl-mr-2">
        <gl-button
          v-if="regexButtonIsVisible"
          v-gl-tooltip.hover
          :title="$options.i18n.label"
          :aria-label="$options.i18n.label"
          class="gl-ml-2 gl-hidden sm:gl-block"
          :class="regexButtonHighlightClass"
          category="secondary"
          variant="default"
          size="small"
          icon="regular-expression"
          data-testid="reqular-expression-toggle"
          @click="regexButtonHandler"
        />
      </div>
    </div>
  </div>
</template>

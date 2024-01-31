<script>
import { GlButton } from '@gitlab/ui';
import { __ } from '~/locale';

export default {
  components: {
    GlButton,
  },
  props: {
    title: {
      type: String,
      required: true,
    },
    isLoading: {
      type: Boolean,
      required: false,
      default: false,
    },
    hasError: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      isCollapsed: true,
    };
  },

  computed: {
    arrowIconName() {
      return this.isCollapsed ? 'chevron-right' : 'chevron-down';
    },
    ariaLabel() {
      return this.isCollapsed ? __('Expand') : __('Collapse');
    },
  },
  methods: {
    toggleCollapsed() {
      this.isCollapsed = !this.isCollapsed;
    },
  },
};
</script>
<template>
  <div class="mr-widget-extension">
    <div class="d-flex gl-align-items-center pl-3 gl-py-3">
      <div v-if="hasError" class="ci-widget media">
        <div class="media-body">
          <span class="gl-font-sm gl-ml-7 gl-line-height-24 js-error-state">
            {{ title }}
          </span>
        </div>
      </div>

      <template v-else>
        <gl-button
          class="gl-mr-3"
          size="small"
          :aria-label="ariaLabel"
          :loading="isLoading"
          :icon="arrowIconName"
          category="tertiary"
          @click="toggleCollapsed"
        />
        <template v-if="isCollapsed">
          <slot name="header"></slot>
          <gl-button
            category="tertiary"
            variant="confirm"
            size="small"
            data-testid="mr-collapsible-title"
            :disabled="isLoading"
            :class="{ 'border-0': isLoading }"
            @click="toggleCollapsed"
          >
            {{ title }}
          </gl-button>
        </template>
        <gl-button
          v-else
          category="tertiary"
          variant="confirm"
          size="small"
          data-testid="mr-collapsible-title"
          :disabled="isLoading"
          :class="{ 'border-0': isLoading }"
          @click="toggleCollapsed"
          >{{ __('Collapse') }}</gl-button
        >
      </template>
    </div>

    <div v-if="!isCollapsed" class="border-top js-slot-container">
      <slot></slot>
    </div>
  </div>
</template>

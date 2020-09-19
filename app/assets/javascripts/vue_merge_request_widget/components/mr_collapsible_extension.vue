<script>
import { GlButton, GlLoadingIcon, GlIcon } from '@gitlab/ui';
import { __ } from '~/locale';

export default {
  components: {
    GlButton,
    GlLoadingIcon,
    GlIcon,
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
      return this.isCollapsed ? 'angle-right' : 'angle-down';
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
  <div>
    <div class="mr-widget-extension d-flex align-items-center pl-3">
      <div v-if="hasError" class="ci-widget media">
        <div class="media-body">
          <span class="gl-font-sm mr-widget-margin-left gl-line-height-24 js-error-state">{{
            title
          }}</span>
        </div>
      </div>

      <template v-else>
        <button
          class="btn-blank btn s32 square gl-mr-3"
          type="button"
          :aria-label="ariaLabel"
          :disabled="isLoading"
          @click="toggleCollapsed"
        >
          <gl-loading-icon v-if="isLoading" />
          <gl-icon v-else :name="arrowIconName" class="js-icon" />
        </button>
        <gl-button
          variant="link"
          class="js-title"
          :disabled="isLoading"
          :class="{ 'border-0': isLoading }"
          @click="toggleCollapsed"
        >
          <template v-if="isCollapsed">{{ title }}</template>
          <template v-else>{{ __('Collapse') }}</template>
        </gl-button>
      </template>
    </div>

    <div v-if="!isCollapsed" class="border-top js-slot-container">
      <slot></slot>
    </div>
  </div>
</template>

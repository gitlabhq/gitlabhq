<script>
import { GlButton, GlLoadingIcon } from '@gitlab/ui';
import { __ } from '~/locale';
import Icon from '~/vue_shared/components/icon.vue';

export default {
  components: {
    GlButton,
    GlLoadingIcon,
    Icon,
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
          <span class="gl-font-size-small mr-widget-margin-left gl-line-height-24 js-error-state">{{
            title
          }}</span>
        </div>
      </div>

      <template v-else>
        <gl-button
          class="btn-blank btn s32 square append-right-default"
          :aria-label="ariaLabel"
          :disabled="isLoading"
          @click="toggleCollapsed"
        >
          <gl-loading-icon v-if="isLoading" />
          <icon v-else :name="arrowIconName" class="js-icon" />
        </gl-button>
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

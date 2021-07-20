<script>
import { GlLoadingIcon, GlSprintf } from '@gitlab/ui';
import { s__, __, sprintf } from '~/locale';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';

/**
 * Renders an inline field, whose value can be copied to the clipboard,
 * for use in the GitLab sidebar (issues, MRs, etc.).
 */
export default {
  name: 'CopyableField',
  components: {
    ClipboardButton,
    GlLoadingIcon,
    GlSprintf,
  },
  props: {
    value: {
      type: String,
      required: true,
    },
    name: {
      type: String,
      required: true,
    },
    isLoading: {
      type: Boolean,
      required: false,
      default: false,
    },
    clipboardTooltipText: {
      type: String,
      required: false,
      default: undefined,
    },
  },
  computed: {
    clipboardProps() {
      return {
        category: 'tertiary',
        tooltipBoundary: 'viewport',
        tooltipPlacement: 'left',
        text: this.value,
        title:
          this.clipboardTooltipText ||
          sprintf(this.$options.i18n.clipboardTooltip, { name: this.name }),
      };
    },
    loadingIconLabel() {
      return sprintf(this.$options.i18n.loadingIconLabel, { name: this.name });
    },
  },
  i18n: {
    loadingIconLabel: __('Loading %{name}'),
    clipboardTooltip: __('Copy %{name}'),
    templateText: s__('Sidebar|%{name}: %{value}'),
  },
};
</script>

<template>
  <div>
    <clipboard-button
      v-if="!isLoading"
      css-class="sidebar-collapsed-icon dont-change-state gl-rounded-0! gl-hover-bg-transparent"
      v-bind="clipboardProps"
    />

    <div
      class="gl-display-flex gl-align-items-center gl-justify-content-space-between hide-collapsed"
    >
      <span
        class="gl-overflow-hidden gl-text-overflow-ellipsis gl-white-space-nowrap"
        :title="value"
      >
        <gl-sprintf :message="$options.i18n.templateText">
          <template #name>{{ name }}</template>
          <template #value>{{ value }}</template>
        </gl-sprintf>
      </span>

      <gl-loading-icon v-if="isLoading" size="sm" inline :label="loadingIconLabel" />
      <clipboard-button v-else size="small" v-bind="clipboardProps" />
    </div>
  </div>
</template>

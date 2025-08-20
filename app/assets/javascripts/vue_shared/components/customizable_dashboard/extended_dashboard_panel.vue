<script>
import { GlPopover, GlDashboardPanel } from '@gitlab/ui';
import { alertVariantIconMap } from '@gitlab/ui/src/utils/constants';
import { isObject } from 'lodash';
import { VARIANT_DANGER, VARIANT_WARNING, VARIANT_INFO } from '~/alert';

/**
 * This component provides a standardized layout and functionality for dashboard panels.
 *
 * It extends [`GlDashboardPanel`](https://design.gitlab.com/storybook/?path=/story/dashboards-dashboards-panel--default) by adding support for various states including loading, error states with different alert variants,
 * and editing mode with configurable actions.
 *
 */

export default {
  name: 'ExtendedDashboardPanel',
  components: {
    GlPopover,
    GlDashboardPanel,
  },
  props: {
    title: {
      type: String,
      required: false,
      default: '',
    },
    tooltip: {
      type: Object,
      required: false,
      default: () => ({}),
    },
    loading: {
      type: Boolean,
      required: false,
      default: false,
    },
    loadingDelayed: {
      type: Boolean,
      required: false,
      default: false,
    },
    showAlertState: {
      type: Boolean,
      required: false,
      default: false,
    },
    alertVariant: {
      type: String,
      required: false,
      default: VARIANT_DANGER,
      validator: (variant) => [VARIANT_WARNING, VARIANT_DANGER, VARIANT_INFO].includes(variant),
    },
    alertPopoverTitle: {
      type: String,
      required: false,
      default: '',
    },
    actions: {
      type: Array,
      required: false,
      default: () => [],
      validator: (actions) => actions.every((a) => isObject(a)),
    },
    editing: {
      type: Boolean,
      required: false,
      default: false,
    },
    bodyContentClasses: {
      type: String,
      required: false,
      default: '',
    },
  },
  data() {
    return {
      dropdownOpen: false,
    };
  },
  computed: {
    borderColor() {
      return this.showAlertState ? this.$options.alertBorderColorMap[this.alertVariant] : '';
    },
    alertIconClasses() {
      return this.showAlertState ? this.$options.alertIconClassMap[this.alertVariant] : '';
    },
    alertIcon() {
      if (this.showAlertState) {
        return this.$options.alertVariantIconMap[this.alertVariant] ?? alertVariantIconMap.danger;
      }

      return '';
    },
    showAlertPopover() {
      return this.showAlertState && !this.dropdownOpen;
    },
    editingActions() {
      return this.editing ? this.actions : [];
    },
  },
  PANEL_POPOVER_DELAY: {
    hide: 500,
  },
  alertVariantIconMap,
  alertBorderColorMap: {
    [VARIANT_DANGER]: 'gl-border-t-red-500',
    [VARIANT_WARNING]: 'gl-border-t-orange-500',
    [VARIANT_INFO]: 'gl-border-t-blue-500',
  },
  alertIconClassMap: {
    [VARIANT_DANGER]: 'gl-text-danger',
    [VARIANT_WARNING]: 'gl-text-warning',
    [VARIANT_INFO]: 'gl-text-blue-500',
  },
};
</script>

<template>
  <gl-dashboard-panel
    container-class="grid-stack-item-content"
    :title="title"
    :title-icon-class="alertIconClasses"
    :title-icon="alertIcon"
    :title-popover="tooltip"
    :loading="loading"
    :loading-delayed="loadingDelayed"
    :loading-delayed-text="__('Still loading…')"
    :actions="editingActions"
    :actions-toggle-text="__('Actions')"
    :border-color-class="borderColor"
    :body-content-class="bodyContentClasses"
    @dropdownOpen="dropdownOpen = true"
    @dropdownClosed="dropdownOpen = false"
  >
    <template #body>
      <slot name="body"></slot>
    </template>
    <template #filters>
      <slot name="filters"></slot>
    </template>
    <template #alert-message="{ panelId }">
      <gl-popover
        v-if="showAlertPopover"
        :aria-describedby="panelId"
        triggers="hover focus"
        :title="alertPopoverTitle"
        :show-close-button="false"
        placement="top"
        :css-classes="['gl-max-w-1/2']"
        :target="panelId"
        :delay="$options.PANEL_POPOVER_DELAY"
        boundary="viewport"
      >
        <!-- @slot The panel error popover body to display when showAlertState is true. -->
        <slot name="alert-popover"></slot>
      </gl-popover>
    </template>
  </gl-dashboard-panel>
</template>

<script>
import { GlIcon, GlAlert, GlTooltipDirective } from '@gitlab/ui';
import { __ } from '~/locale';
import { TYPE_EPIC, WORKSPACE_GROUP, WORKSPACE_PROJECT } from '~/issues/constants';
import { confidentialityInfoText } from '~/vue_shared/constants';

export default {
  components: {
    GlIcon,
    GlAlert,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    confidential: {
      type: Boolean,
      required: true,
    },
    issuableType: {
      type: String,
      required: true,
    },
  },
  computed: {
    confidentialBodyText() {
      return confidentialityInfoText(
        this.issuableType === TYPE_EPIC ? WORKSPACE_GROUP : WORKSPACE_PROJECT,
        this.issuableType,
      );
    },
    confidentialIcon() {
      return this.confidential ? 'eye-slash' : 'eye';
    },
    tooltipLabel() {
      return this.confidential ? __('Confidential') : __('Not confidential');
    },
  },
};
</script>

<template>
  <div>
    <div
      v-gl-tooltip.viewport.left
      :title="tooltipLabel"
      class="sidebar-collapsed-icon"
      data-testid="sidebar-collapsed-icon"
      @click="$emit('expandSidebar')"
    >
      <gl-icon
        :size="16"
        :name="confidentialIcon"
        class="sidebar-item-icon gl-inline-block"
        :class="{ 'is-active': confidential }"
      />
    </div>
    <gl-icon
      :size="16"
      :name="confidentialIcon"
      class="sidebar-item-icon hide-collapsed gl-inline-block"
      :class="{ 'is-active': confidential }"
    />
    <span class="hide-collapsed" data-testid="confidential-text">
      {{ tooltipLabel }}
      <gl-alert
        v-if="confidential"
        :show-icon="false"
        :dismissible="false"
        variant="warning"
        class="gl-mt-3"
      >
        {{ confidentialBodyText }}
      </gl-alert>
    </span>
  </div>
</template>

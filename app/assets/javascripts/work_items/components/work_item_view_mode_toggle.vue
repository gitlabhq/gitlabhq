<script>
import { GlButton, GlButtonGroup, GlTooltipDirective } from '@gitlab/ui';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { hasBoardViewMode, viewModeOptions } from 'ee_else_ce/work_items/view_modes';
import { VIEW_MODE_BOARD, VIEW_MODE_TABLE } from '../constants';

export default {
  name: 'WorkItemViewModeToggle',
  components: {
    GlButton,
    GlButtonGroup,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  mixins: [glFeatureFlagMixin()],
  props: {
    viewMode: {
      type: String,
      required: true,
    },
  },
  emits: ['toggle-view-mode'],
  computed: {
    availableViewModeOptions() {
      return viewModeOptions.filter((option) => {
        if (option.value === VIEW_MODE_TABLE) {
          return Boolean(this.glFeatures.planningViewTable);
        }
        if (option.value === VIEW_MODE_BOARD) {
          return hasBoardViewMode && Boolean(this.glFeatures.planningViewBoards);
        }
        return true;
      });
    },
  },
  methods: {
    onToggleViewMode(newViewMode) {
      this.$emit('toggle-view-mode', newViewMode);
    },
    isPressed(value) {
      return value === this.viewMode ? 'true' : 'false';
    },
  },
};
</script>

<template>
  <div v-if="availableViewModeOptions.length > 1">
    <gl-button-group class="@md/panel:gl-hidden" data-testid="view-mode-icon-toggle">
      <gl-button
        v-for="option in availableViewModeOptions"
        :key="option.value"
        v-gl-tooltip
        :icon="option.props.icon"
        :title="option.text"
        :aria-label="option.text"
        :aria-pressed="isPressed(option.value)"
        :selected="option.value === viewMode"
        :data-testid="`view-mode-icon-${option.value}`"
        @click="onToggleViewMode(option.value)"
      />
    </gl-button-group>
    <gl-button-group
      class="gl-hidden @md/panel:gl-inline-flex"
      data-testid="view-mode-label-toggle"
    >
      <gl-button
        v-for="option in availableViewModeOptions"
        :key="option.value"
        :aria-pressed="isPressed(option.value)"
        :selected="option.value === viewMode"
        :data-testid="`view-mode-label-${option.value}`"
        @click="onToggleViewMode(option.value)"
      >
        {{ option.text }}
      </gl-button>
    </gl-button-group>
  </div>
</template>

<script>
import { GlButton, GlDropdown, GlDropdownItem, GlTooltipDirective } from '@gitlab/ui';
import { sprintf, __ } from '~/locale';

export default {
  components: {
    GlButton,
    GlDropdown,
    GlDropdownItem,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    widget: {
      type: String,
      required: false,
      default: '',
    },
    tertiaryButtons: {
      type: Array,
      required: false,
      default: () => [],
    },
  },
  data: () => {
    return {
      timeout: null,
      updatingTooltip: false,
    };
  },
  computed: {
    dropdownLabel() {
      if (!this.widget) return undefined;

      return sprintf(__('%{widget} options'), { widget: this.widget });
    },
  },
  methods: {
    onClickAction(action) {
      this.$emit('clickedAction', action);

      if (action.onClick) {
        action.onClick();
      }

      if (action.tooltipOnClick) {
        this.updatingTooltip = true;
        this.$root.$emit('bv::show::tooltip', action.id);

        clearTimeout(this.timeout);

        this.timeout = setTimeout(() => {
          this.updatingTooltip = false;
          this.$root.$emit('bv::hide::tooltip', action.id);
        }, 1000);
      }
    },
    setTooltip(btn) {
      if (this.updatingTooltip && btn.tooltipOnClick) {
        return btn.tooltipOnClick;
      }

      return btn.tooltipText;
    },
    actionButtonQaSelector(btn) {
      if (btn.dataQaSelector) {
        return btn.dataQaSelector;
      }
      return 'mr_widget_extension_actions_button';
    },
  },
};
</script>

<template>
  <div class="gl-display-flex gl-align-items-flex-start">
    <gl-dropdown
      v-if="tertiaryButtons.length"
      v-gl-tooltip
      :title="__('Options')"
      :text="dropdownLabel"
      icon="ellipsis_v"
      no-caret
      category="tertiary"
      right
      lazy
      text-sr-only
      size="small"
      toggle-class="gl-p-2!"
      class="gl-display-block gl-md-display-none!"
    >
      <gl-dropdown-item
        v-for="(btn, index) in tertiaryButtons"
        :key="index"
        :href="btn.href"
        :target="btn.target"
        :data-clipboard-text="btn.dataClipboardText"
        :data-method="btn.dataMethod"
        @click="onClickAction(btn)"
      >
        {{ btn.text }}
      </gl-dropdown-item>
    </gl-dropdown>
    <template v-if="tertiaryButtons.length">
      <gl-button
        v-for="(btn, index) in tertiaryButtons"
        :id="btn.id"
        :key="index"
        v-gl-tooltip.hover
        :title="setTooltip(btn)"
        :href="btn.href"
        :target="btn.target"
        :class="[{ 'gl-mr-3': index !== tertiaryButtons.length - 1 }, btn.class]"
        :data-clipboard-text="btn.dataClipboardText"
        :data-qa-selector="actionButtonQaSelector(btn)"
        :data-method="btn.dataMethod"
        :icon="btn.icon"
        :data-testid="btn.testId || 'extension-actions-button'"
        :variant="btn.variant || 'confirm'"
        :loading="btn.loading"
        :disabled="btn.loading"
        category="tertiary"
        size="small"
        class="gl-display-none gl-md-display-block gl-float-left"
        @click="onClickAction(btn)"
      >
        <template v-if="btn.text">
          {{ btn.text }}
        </template>
      </gl-button>
    </template>
  </div>
</template>

<script>
import {
  GlButton,
  GlPopover,
  GlSprintf,
  GlLink,
  GlDropdown,
  GlDropdownItem,
  GlTooltipDirective,
} from '@gitlab/ui';
import { sprintf, __ } from '~/locale';

export default {
  components: {
    GlButton,
    GlPopover,
    GlSprintf,
    GlLink,
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
    hasOneOption() {
      return this.tertiaryButtons.length === 1;
    },
    hasMultipleOptions() {
      return this.tertiaryButtons.length > 1;
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
    <template v-if="hasOneOption">
      <span v-for="(btn, index) in tertiaryButtons" :key="index">
        <gl-button
          :id="btn.id"
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
          class="gl-md-display-block gl-float-left"
          @click="onClickAction(btn)"
        >
          {{ btn.text }}
        </gl-button>
        <gl-popover v-if="btn.popoverTarget" :target="btn.popoverTarget">
          <template #title> {{ btn.popoverTitle }} </template>

          <span v-if="btn.popoverLink">
            <gl-sprintf :message="btn.popoverText">
              <template #link="{ content }">
                <gl-link class="gl-font-sm" :href="btn.popoverLink" target="_blank">
                  {{ content }}</gl-link
                >
              </template>
            </gl-sprintf>
          </span>
          <span v-else>
            {{ btn.popoverText }}
          </span>
        </gl-popover>
      </span>
    </template>
    <template v-if="hasMultipleOptions">
      <gl-dropdown
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
      <span v-for="(btn, index) in tertiaryButtons" :key="index">
        <gl-button
          :id="btn.id"
          v-gl-tooltip.hover
          :title="setTooltip(btn)"
          :href="btn.href"
          :target="btn.target"
          :class="[{ 'gl-mr-1': index !== tertiaryButtons.length - 1 }, btn.class]"
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
          {{ btn.text }}
        </gl-button>
        <gl-popover v-if="btn.popoverTarget" :target="btn.popoverTarget">
          <template #title> {{ btn.popoverTitle }} </template>

          <span v-if="btn.popoverLink">
            <gl-sprintf :message="btn.popoverText">
              <template #link="{ content }">
                <gl-link class="gl-font-sm" :href="btn.popoverLink" target="_blank">
                  {{ content }}</gl-link
                >
              </template>
            </gl-sprintf>
          </span>
          <span v-else>
            {{ btn.popoverText }}
          </span>
        </gl-popover>
      </span>
    </template>
  </div>
</template>

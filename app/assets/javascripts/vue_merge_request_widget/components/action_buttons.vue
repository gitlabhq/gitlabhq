<script>
import {
  GlButton,
  GlPopover,
  GlSprintf,
  GlLink,
  GlDisclosureDropdown,
  GlTooltipDirective,
} from '@gitlab/ui';

export default {
  name: 'ActionButtons',
  components: {
    GlButton,
    GlPopover,
    GlSprintf,
    GlLink,
    GlDisclosureDropdown,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    tertiaryButtons: {
      type: Array,
      // fix `spec/frontend/vue_merge_request_widget/mr_widget_options_spec.js` before making this required
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
    hasOneOption() {
      return this.tertiaryButtons.length === 1;
    },
    hasMultipleOptions() {
      return this.tertiaryButtons.length > 1;
    },
    dropdownItems() {
      return this.tertiaryButtons.map((item) => {
        return {
          ...item,
          text: item.text,
          href: item.href,
          extraAttrs: {
            dataClipboardText: item.dataClipboardText,
            dataMethod: item.dataMethod,
            target: item.target,
          },
        };
      });
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
  },
};
</script>

<template>
  <div class="gl-flex gl-items-start">
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
          :data-method="btn.dataMethod"
          :icon="btn.icon"
          :data-testid="btn.testId || 'extension-actions-button'"
          :variant="btn.variant || 'confirm'"
          :loading="btn.loading"
          :disabled="btn.disabled || btn.loading"
          category="tertiary"
          size="small"
          class="gl-float-left md:gl-inline-flex"
          @click="onClickAction(btn)"
        >
          {{ btn.text }}
        </gl-button>
        <gl-popover v-if="btn.popoverTarget" :target="btn.popoverTarget">
          <template #title> {{ btn.popoverTitle }} </template>

          <span v-if="btn.popoverLink">
            <gl-sprintf :message="btn.popoverText">
              <template #link="{ content }">
                <gl-link class="gl-text-sm" :href="btn.popoverLink" target="_blank">
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
      <gl-disclosure-dropdown
        v-gl-tooltip
        :items="dropdownItems"
        :title="__('Options')"
        icon="ellipsis_v"
        no-caret
        category="tertiary"
        text-sr-only
        size="small"
        class="gl-block md:!gl-hidden"
        @action="onClickAction"
      />
      <span v-for="(btn, index) in tertiaryButtons" :key="index">
        <gl-button
          :id="btn.id"
          v-gl-tooltip.hover
          :title="setTooltip(btn)"
          :href="btn.href"
          :target="btn.target"
          :class="[{ 'gl-mr-3': index !== tertiaryButtons.length - 1 }, btn.class]"
          :data-clipboard-text="btn.dataClipboardText"
          :data-method="btn.dataMethod"
          :icon="btn.icon"
          :data-testid="btn.testId || 'extension-actions-button'"
          :variant="btn.variant || 'confirm'"
          :loading="btn.loading"
          :disabled="btn.disabled || btn.loading"
          category="tertiary"
          size="small"
          class="gl-float-left gl-hidden md:gl-inline-flex"
          @click="onClickAction(btn)"
        >
          {{ btn.text }}
        </gl-button>
        <gl-popover v-if="btn.popoverTarget" :target="btn.popoverTarget">
          <template #title> {{ btn.popoverTitle }} </template>

          <span v-if="btn.popoverLink">
            <gl-sprintf :message="btn.popoverText">
              <template #link="{ content }">
                <gl-link class="gl-text-sm" :href="btn.popoverLink" target="_blank">
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

<script>
import {
  GlButton,
  GlDisclosureDropdown,
  GlIcon,
  GlLoadingIcon,
  GlTooltipDirective,
} from '@gitlab/ui';

export default {
  components: {
    GlButton,
    GlDisclosureDropdown,
    GlIcon,
    GlLoadingIcon,
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
      required: true,
    },
  },
  data() {
    return {
      timeout: null,
      updatingTooltip: false,
    };
  },
  computed: {
    dropdownItems() {
      return this.tertiaryButtons.map((button) => {
        return {
          text: button.text,
          href: button.href,
          action: () => this.onClickAction(button),
          icon: button.icon || button.iconName,
          loading: button.loading,
          extraAttrs: {
            dataClipboardText: button.dataClipboardText,
            dataMethod: button.dataMethod,
            target: button.target,
            disabled: button.disabled,
          },
        };
      });
    },
  },
  methods: {
    onClickAction(action, e = null) {
      this.$emit('clickedAction', action);

      if (action.onClick) {
        action.onClick(action, e);
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
    <gl-disclosure-dropdown
      :items="dropdownItems"
      icon="ellipsis_v"
      no-caret
      category="tertiary"
      placement="bottom-end"
      text-sr-only
      size="small"
      toggle-class="!gl-p-2"
      class="gl-block md:!gl-hidden"
    >
      <template #list-item="{ item }">
        <span class="gl-flex gl-items-center gl-justify-between">
          {{ item.text }}
          <gl-loading-icon v-if="item.loading" size="sm" />
          <gl-icon v-else-if="item.icon" :name="item.icon" />
        </span>
      </template>
    </gl-disclosure-dropdown>
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
      :data-method="btn.dataMethod"
      :icon="btn.icon || btn.iconName"
      :data-testid="btn.testId || 'extension-actions-button'"
      :variant="btn.variant || 'confirm'"
      :loading="btn.loading"
      :disabled="btn.loading"
      category="tertiary"
      size="small"
      class="gl-float-left gl-hidden md:gl-inline-flex"
      @click="($event) => onClickAction(btn, $event)"
    >
      <template v-if="btn.text">
        {{ btn.text }}
      </template>
    </gl-button>
  </div>
</template>

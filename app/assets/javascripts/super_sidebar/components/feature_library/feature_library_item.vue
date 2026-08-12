<script>
import { GlButton, GlIcon, GlLink, GlTooltipDirective } from '@gitlab/ui';
import { sprintf, __, s__ } from '~/locale';
import { TIERS } from './constants';

export default {
  name: 'FeatureLibraryItem',
  components: { GlButton, GlIcon, GlLink },
  directives: { GlTooltip: GlTooltipDirective },
  i18n: {
    pinLabel: s__('FeatureLibrary|Pin %{title}'),
    unpinLabel: s__('FeatureLibrary|Unpin %{title}'),
    pinTooltip: s__('FeatureLibrary|Pin'),
    unpinTooltip: s__('FeatureLibrary|Unpin'),
  },
  props: {
    supportsPins: {
      type: Boolean,
      required: false,
      default: false,
    },
    item: {
      type: Object,
      required: true,
    },
    pinned: {
      type: Boolean,
      required: false,
      default: false,
    },
    solidBackground: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  emits: ['pin-toggle', 'navigate'],
  computed: {
    tierLabel() {
      switch (this.item.tier) {
        case TIERS.PREMIUM:
          return __('Premium');
        case TIERS.ULTIMATE:
          return __('Ultimate');
        case TIERS.ADD_ON:
          return __('Add-on');
        default:
          return __('Free');
      }
    },
    pinAriaLabel() {
      const template = this.pinned ? this.$options.i18n.unpinLabel : this.$options.i18n.pinLabel;
      return sprintf(template, { title: this.item.title });
    },
    pinIconName() {
      return this.pinned ? 'thumbtack-solid' : 'thumbtack';
    },
    pinTooltipText() {
      return this.pinned ? this.$options.i18n.unpinTooltip : this.$options.i18n.pinTooltip;
    },
  },
  methods: {
    onPinClick() {
      this.$emit('pin-toggle', this.item.id, !this.pinned, this.item.title);
    },
    onNavigate() {
      this.$emit('navigate', this.item.id);
    },
    // eslint-disable-next-line vue/no-unused-properties -- invoked externally via this.$refs.searchResultItems in feature_library_modal.vue
    focus() {
      this.$refs.titleLink?.$el?.focus();
    },
  },
};
</script>

<template>
  <li
    class="gl-flex gl-flex-col gl-rounded-xl gl-border-1 gl-border-solid gl-border-section gl-pt-4"
    :class="
      solidBackground ? 'gl-bg-default hover:gl-shadow-md' : 'gl-bg-section hover:gl-bg-subtle'
    "
  >
    <!-- The title link stretches over this wrapper only, so the pin action
         stays outside the link's click target. -->
    <div class="gl-relative gl-grow gl-px-4" data-testid="feature-library-item-content">
      <span class="gl-inline-flex gl-items-center gl-gap-2">
        <gl-icon :name="item.icon" class="gl-shrink-0" />
        <gl-link
          ref="titleLink"
          variant="meta"
          :href="item.link"
          class="gl-text-lg gl-font-semibold gl-stretched-link"
          data-testid="feature-library-item-title"
          @click="onNavigate"
        >
          {{ item.title }}
        </gl-link>
      </span>

      <p data-testid="feature-library-item-description" class="gl-mb-0 gl-mt-1 gl-text-subtle">
        {{ item.description }}
      </p>
    </div>
    <div
      class="gl-mt-3 gl-flex gl-items-center gl-justify-between gl-border-t-1 gl-border-t-section gl-py-3 gl-pl-4 gl-pr-3 gl-border-t-solid"
    >
      <span data-testid="feature-library-item-tier" class="gl-text-sm gl-text-subtle">
        {{ tierLabel }}
      </span>
      <gl-button
        v-if="supportsPins"
        v-gl-tooltip.hover="pinTooltipText"
        category="tertiary"
        size="small"
        :icon="pinIconName"
        :aria-label="pinAriaLabel"
        :aria-pressed="pinned"
        :selected="pinned"
        @click="onPinClick"
      />
    </div>
  </li>
</template>

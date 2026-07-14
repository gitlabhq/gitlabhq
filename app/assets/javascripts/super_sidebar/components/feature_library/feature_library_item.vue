<script>
import { GlButton, GlBadge, GlIcon, GlLink, GlTooltipDirective } from '@gitlab/ui';
import { sprintf, __, s__ } from '~/locale';
import { TIERS } from './constants';

export default {
  name: 'FeatureLibraryItem',
  components: { GlButton, GlBadge, GlIcon, GlLink },
  directives: { GlTooltip: GlTooltipDirective },
  i18n: {
    pinLabel: s__('FeatureLibrary|Pin %{title}'),
    unpinLabel: s__('FeatureLibrary|Unpin %{title}'),
    pinTooltip: s__('FeatureLibrary|Pin'),
    unpinTooltip: s__('FeatureLibrary|Unpin'),
  },
  props: {
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
          return null;
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
  },
};
</script>

<template>
  <li
    class="gl-flex gl-items-start gl-gap-3 gl-rounded-xl gl-p-4"
    :class="
      solidBackground ? 'gl-bg-default hover:gl-shadow-md' : 'gl-bg-transparent hover:gl-bg-strong'
    "
  >
    <gl-icon :name="item.icon" class="gl-mt-1 gl-shrink-0" />
    <div class="gl-min-w-0 gl-flex-grow">
      <span class="gl-inline-flex gl-items-center gl-gap-2 gl-text-lg gl-font-semibold">
        <gl-link
          v-if="item.link"
          variant="meta"
          :href="item.link"
          data-testid="feature-library-item-title"
          @click="onNavigate"
        >
          {{ item.title }}
        </gl-link>
        <span v-else data-testid="feature-library-item-title">
          {{ item.title }}
        </span>
        <gl-badge v-if="tierLabel" data-testid="feature-library-item-tier">
          {{ tierLabel }}
        </gl-badge>
      </span>

      <p data-testid="feature-library-item-description" class="gl-mb-0 gl-mt-1 gl-text-subtle">
        {{ item.description }}
      </p>
    </div>
    <gl-button
      v-gl-tooltip.hover="pinTooltipText"
      category="tertiary"
      class="-gl-m-2"
      :icon="pinIconName"
      :aria-label="pinAriaLabel"
      :aria-pressed="pinned"
      :selected="pinned"
      @click="onPinClick"
    />
  </li>
</template>

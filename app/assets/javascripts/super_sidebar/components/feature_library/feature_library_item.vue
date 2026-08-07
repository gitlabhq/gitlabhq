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
    class="gl-relative gl-flex gl-flex-col gl-rounded-xl gl-border-1 gl-border-solid gl-border-section gl-pt-4"
    :class="
      solidBackground ? 'gl-bg-default hover:gl-shadow-md' : 'gl-bg-section hover:gl-bg-subtle'
    "
  >
    <!-- The title link stretches over this wrapper only, so the pin action
         stays outside the link's click target. -->
    <div
      class="gl-relative gl-flex gl-min-w-0 gl-grow gl-flex-col gl-items-start gl-gap-2 gl-px-4"
      data-testid="feature-library-item-content"
    >
      <gl-icon :name="item.icon" class="gl-shrink-0" />
      <div class="gl-min-w-0 gl-flex-grow">
        <span class="gl-inline-flex gl-items-center gl-gap-2 gl-text-lg gl-font-semibold">
          <!-- eslint-disable tailwindcss/no-arbitrary-value -->
          <gl-link
            v-if="item.link"
            ref="titleLink"
            variant="meta"
            :href="item.link"
            class="after:gl-absolute after:gl-inset-0 after:gl-content-['']"
            data-testid="feature-library-item-title"
            @click="onNavigate"
          >
            {{ item.title }}
          </gl-link>
          <!-- eslint-enable tailwindcss/no-arbitrary-value -->
          <span v-else data-testid="feature-library-item-title">
            {{ item.title }}
          </span>
        </span>

        <p data-testid="feature-library-item-description" class="gl-mb-0 gl-mt-1 gl-text-subtle">
          {{ item.description }}
        </p>
      </div>
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

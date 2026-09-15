<script>
import { uniqueId } from 'lodash-es';
import { GlButton, GlDrawer, GlTooltipDirective } from '@gitlab/ui';
import { __ } from '~/locale';
import { DRAWER_Z_INDEX } from '~/lib/utils/constants';
import { glSlotsMixin } from '~/lib/utils/vue3compat/gl_slots_mixin';

/**
 * ExtendedDrawer extends GlDrawer with an expanded (full content width) state
 * and an optional secondary content area that renders only while expanded.
 * The component manages its own open and expanded state, seeded and updated
 * by the `open` and `expanded` props, and reports every transition through
 * the `close`, `update:open`, `expand` and `collapse` events, so consumers
 * can bind `:open.sync` and stay aligned with self-closes. The
 * expand/collapse toggle renders in the header next to the title.
 *
 * Content states stay with the consumer: loading and empty treatments belong
 * to the slots (including a secondary area shown before its content arrives),
 * and scroll position or selection is not preserved when slot content
 * updates, so feeds that stream rows own that behavior.
 */
export default {
  name: 'ExtendedDrawer',
  components: {
    GlButton,
    GlDrawer,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  mixins: [glSlotsMixin],
  i18n: {
    expandLabel: __('Expand to full width'),
    collapseLabel: __('Collapse to drawer'),
  },
  props: {
    /**
     * Controls the visibility state of the drawer. Passed through to GlDrawer.
     * Self-closes (Escape, the close button) report through `update:open`,
     * so `.sync` bindings stay aligned and can reopen the drawer later.
     */
    open: {
      type: Boolean,
      required: true,
    },
    /**
     * Accessible title of the drawer, rendered as the header heading and used
     * to label the drawer region.
     */
    title: {
      type: String,
      required: true,
    },
    /**
     * When true, the drawer takes the full width and the `secondary` slot
     * (when provided) renders beside the default slot.
     */
    expanded: {
      type: Boolean,
      required: false,
      default: false,
    },
    /**
     * Height of the fixed chrome above the drawer (e.g. '48px').
     * Passed through to GlDrawer.
     */
    headerHeight: {
      type: String,
      required: false,
      default: '',
    },
    /**
     * When true, keeps the drawer header visible while scrolling.
     * Passed through to GlDrawer.
     */
    headerSticky: {
      type: Boolean,
      required: false,
      default: false,
    },
    /**
     * Stacking order of the drawer. Passed through to GlDrawer.
     */
    zIndex: {
      type: Number,
      required: false,
      default: DRAWER_Z_INDEX,
    },
    /**
     * Whether the secondary area is currently shown (when expanded and the
     * `secondary` slot is provided). Consumers whose secondary content
     * appears conditionally (for example after a selection) must always
     * provide the slot and drive this prop instead of v-if-ing the slot:
     * conditionally provided slots are not reactive in the slot-presence
     * check, so a slot added after mount would never be detected.
     */
    secondaryVisible: {
      type: Boolean,
      required: false,
      default: true,
    },
    /**
     * Accessible name of the primary scroll region while the split shows.
     * Distinct from the drawer title so region navigation does not announce
     * the same name twice.
     */
    primaryLabel: {
      type: String,
      required: false,
      default: __('Primary content'),
    },
    /**
     * Accessible name of the secondary scroll region.
     */
    secondaryLabel: {
      type: String,
      required: false,
      default: __('Details'),
    },
  },
  emits: ['close', 'collapse', 'expand', 'opened', 'update:open'],
  data() {
    return {
      titleId: uniqueId('extended-drawer-title-'),
      isOpen: this.open,
      isExpanded: this.expanded,
    };
  },
  computed: {
    showSecondary() {
      return this.isExpanded && this.secondaryVisible && Boolean(this.glSlots().secondary);
    },
    stickyHeader() {
      // GlDrawer's sticky-header mode is its only hook that constrains
      // .gl-drawer-body; without it the body grows with the content and the
      // whole drawer scrolls instead of the two columns. Side effect: it also
      // raises the header to GlDrawer's max z-index while the split shows.
      return this.headerSticky || this.showSecondary;
    },
    toggleLabel() {
      return this.isExpanded ? this.$options.i18n.collapseLabel : this.$options.i18n.expandLabel;
    },
    toggleIcon() {
      return this.isExpanded ? 'collapse-right' : 'collapse-left';
    },
  },
  watch: {
    // isOpen is a local mirror so close() can hide the drawer on its own; it
    // still has to follow the consumer's prop, otherwise reopening never lands.
    open(value) {
      this.isOpen = value;
    },
    // Same mirror contract for expanded: the prop stays authoritative.
    expanded(value) {
      this.isExpanded = value;
    },
    isOpen(value) {
      if (!value) this.restoreReturnFocus();
    },
    showSecondary(value, oldValue) {
      if (oldValue && !value) this.handOffSecondaryFocus();
    },
  },
  created() {
    // Deliberately non-reactive: a DOM element only read during focus handoffs.
    this.returnFocusElement = null;
  },
  mounted() {
    // GlDrawer's transition has no `appear` hook, so @opened never fires for a
    // drawer that mounts open; take focus here for that case.
    if (this.isOpen) {
      this.captureReturnFocus();
      this.$nextTick(() => {
        this.$refs.drawer?.$el?.focus();
      });
    }
  },
  methods: {
    onOpened() {
      // GlDrawer manages Escape but not focus; move focus into the drawer so
      // keyboard and screen reader users land on the newly opened region, and
      // remember where they came from for the close restore.
      this.captureReturnFocus();
      this.$refs.drawer.$el.focus();
      this.$emit('opened');
    },
    close() {
      this.isOpen = false;
      this.$emit('update:open', false);
      this.$emit('close');
    },
    captureReturnFocus() {
      const { activeElement } = document;
      this.returnFocusElement =
        activeElement && activeElement !== document.body ? activeElement : null;
    },
    restoreReturnFocus() {
      const target = this.returnFocusElement;
      this.returnFocusElement = null;
      if (!target || !target.isConnected) return;
      const { activeElement } = document;
      const drawerEl = this.$refs.drawer?.$el;
      // Restore only when focus would otherwise be dropped: it still sits
      // inside the closing drawer, or already fell back to the body.
      if (activeElement === document.body || drawerEl?.contains(activeElement)) {
        target.focus();
      }
    },
    handOffSecondaryFocus() {
      // Runs before the DOM removes the region, so the containment check still
      // sees where focus is.
      const region = this.$refs.secondaryRegion;
      if (region?.contains(document.activeElement)) {
        this.$nextTick(() => {
          this.$refs.toggleButton?.$el?.focus();
        });
      }
    },
    toggleExpanded() {
      if (this.isExpanded) {
        this.isExpanded = false;
        this.$emit('collapse');
      } else {
        this.isExpanded = true;
        this.$emit('expand');
      }
    },
  },
};
</script>

<template>
  <gl-drawer
    ref="drawer"
    :open="isOpen"
    :header-height="headerHeight"
    :header-sticky="stickyHeader"
    :z-index="zIndex"
    :aria-labelledby="titleId"
    tabindex="-1"
    class="gl-@container"
    :class="{ '!gl-w-full': isExpanded }"
    data-testid="extended-drawer"
    @opened="onOpened"
    @close="close"
  >
    <template #title>
      <h2 :id="titleId" class="gl-heading-3 gl-mb-0 gl-grow">{{ title }}</h2>
      <gl-button
        ref="toggleButton"
        v-gl-tooltip.bottom="toggleLabel"
        category="tertiary"
        size="small"
        :icon="toggleIcon"
        class="gl-mr-2 gl-self-start"
        :aria-label="toggleLabel"
        data-testid="extended-drawer-expand-button"
        @click="toggleExpanded"
      />
    </template>

    <template v-if="glSlots().header" #header>
      <!-- @slot Additional header content below the title row. Passed through to GlDrawer. -->
      <slot name="header"></slot>
    </template>

    <!-- The @md: variants query the gl-@container on the drawer root, so the
         split follows the drawer's own width rather than the viewport. -->
    <div
      data-testid="extended-drawer-split"
      :class="{ 'gl-min-h-0 !gl-p-0 @md:gl-grid @md:gl-h-full @md:gl-grid-cols-3': showSecondary }"
    >
      <div
        data-testid="extended-drawer-primary"
        :class="{
          'gl-border-b gl-flex gl-min-h-0 gl-flex-col @md:gl-border-r @md:gl-overflow-hidden @md:gl-border-b-0':
            showSecondary,
        }"
      >
        <!-- The split-mode scroll regions are focusable so keyboard users can
             scroll them (axe: scrollable-region-focusable). Below the md
             container width the areas stack into one column and the drawer
             body scrolls as one. -->
        <div
          class="gl-@container"
          :class="{
            'gl-min-h-0 gl-p-5 focus-visible:gl-focus @md:gl-grow @md:gl-overflow-y-auto':
              showSecondary,
          }"
          :role="showSecondary ? 'region' : null"
          :aria-label="showSecondary ? primaryLabel : null"
          :tabindex="showSecondary ? 0 : null"
          data-testid="extended-drawer-primary-scroll"
        >
          <!-- @slot Primary content. Becomes the left column, scrolling independently, when the secondary area shows. -->
          <slot></slot>
        </div>
      </div>
      <div
        v-if="showSecondary"
        ref="secondaryRegion"
        class="gl-min-h-0 gl-p-5 gl-@container focus-visible:gl-focus @md:gl-col-span-2 @md:gl-overflow-y-auto"
        role="region"
        :aria-label="secondaryLabel"
        tabindex="0"
        data-testid="extended-drawer-secondary"
      >
        <!-- @slot Optional second content area. Renders only while expanded and secondaryVisible; scrolls independently of the primary area. -->
        <slot name="secondary"></slot>
      </div>
    </div>

    <template v-if="glSlots().footer" #footer>
      <!-- @slot Sticky footer content. Passed through to GlDrawer. -->
      <slot name="footer"></slot>
    </template>
  </gl-drawer>
</template>

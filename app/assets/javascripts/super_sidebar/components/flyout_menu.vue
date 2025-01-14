<script>
import { computePosition, autoUpdate, offset, flip, shift } from '@floating-ui/dom';
import NavItem from './nav_item.vue';

// Flyout menus are shown when the MenuSection's title is hovered with the mouse.
// Their position is dynamically calculated with floating-ui.
//
// Since flyout menus show all NavItems of a section, they can be very long and
// a user might want to move their mouse diagonally from the section title down
// to last nav item in the flyout. But this mouse movement over other sections
// would loose hover and close the flyout, opening another section's flyout.
// To avoid this annoyance, our flyouts come with a "diagonal tolerance". This
// is an area between the current mouse position and the top- and bottom-left
// corner of the flyout itself. While the mouse stays within this area and
// reaches the flyout before a timer expires, the native browser hover stays
// within the component.
// This is done with an transparent SVG positioned left of the flyout menu,
// overlapping the sidebar. The SVG itself ignores pointer events but its two
// triangles, one above the section title, one below, do listen to events,
// keeping hover.

// The flyout menu gets some padding, to keep it open when the cursor goes out
// of bounds just a little bit. This padding is compensated with an offset, to
// not have any visual effect.
export const FLYOUT_PADDING = 12;

export default {
  name: 'FlyoutMenu',
  components: { NavItem },
  props: {
    targetId: {
      type: String,
      required: true,
    },
    items: {
      type: Array,
      required: true,
    },
    asyncCount: {
      type: Object,
      required: false,
      default: () => ({}),
    },
  },
  data() {
    return {
      currentMouseX: 0,
      flyoutX: 0,
      flyoutY: 0,
      flyoutHeight: 0,
      hoverTimeoutId: null,
      showSVG: true,
      targetRect: null,
    };
  },
  cleanupFunction: undefined,
  computed: {
    topSVGPoints() {
      const x = (this.currentMouseX / this.targetRect.width) * 100;
      let y = ((this.targetRect.top - this.flyoutY) / this.flyoutHeight) * 100;
      y += 1; // overlap title to not loose hover

      return `${x}, ${y} 100, 0 100, ${y}`;
    },
    bottomSVGPoints() {
      const x = (this.currentMouseX / this.targetRect.width) * 100;
      let y = ((this.targetRect.bottom - this.flyoutY) / this.flyoutHeight) * 100;
      y -= 1; // overlap title to not loose hover

      return `${x}, ${y} 100, ${y} 100, 100`;
    },
    flyoutStyle() {
      return {
        padding: `${FLYOUT_PADDING}px`,
        // Add extra padding on the left, to completely overlap the scrollbar of
        // the sidebar, which can be pretty wide, depending on the user's browser.
        // See https://gitlab.com/gitlab-org/gitlab/-/issues/426023
        'padding-left': `${FLYOUT_PADDING * 2}px`,
      };
    },
  },
  created() {
    const target = document.querySelector(`#${this.targetId}`);
    target.addEventListener('mousemove', this.onMouseMove);
  },
  mounted() {
    const target = document.querySelector(`#${this.targetId}`);
    const flyout = document.querySelector(`#${this.targetId}-flyout`);
    const sidebar = document.querySelector('#super-sidebar');

    const updatePosition = () =>
      computePosition(target, flyout, {
        middleware: [
          offset({
            mainAxis: -FLYOUT_PADDING,
            alignmentAxis: -FLYOUT_PADDING,
          }),
          flip(),
          shift(),
        ],
        placement: 'right-start',
        strategy: 'fixed',
      }).then(({ x, y }) => {
        Object.assign(flyout.style, {
          left: `${x}px`,
          top: `${y}px`,
        });
        this.flyoutX = x;
        this.flyoutY = y;
        this.flyoutHeight = flyout.clientHeight;

        // Flyout coordinates are relative to the sidebar which can be
        // shifted down by the performance-bar etc.
        // Adjust viewport coordinates from getBoundingClientRect:
        const targetRect = target.getBoundingClientRect();
        const sidebarRect = sidebar.getBoundingClientRect();
        this.targetRect = {
          top: targetRect.top - sidebarRect.top,
          bottom: targetRect.bottom - sidebarRect.top,
          width: targetRect.width,
        };
      });

    this.$options.cleanupFunction = autoUpdate(target, flyout, updatePosition);
  },
  beforeUnmount() {
    this.$options.cleanupFunction?.();
    clearTimeout(this.hoverTimeoutId);
  },
  beforeDestroy() {
    const target = document.querySelector(`#${this.targetId}`);
    target.removeEventListener('mousemove', this.onMouseMove);
  },
  methods: {
    startHoverTimeout() {
      this.hoverTimeoutId = setTimeout(() => {
        this.showSVG = false;
        this.$emit('mouseleave');
      }, 1000);
    },
    stopHoverTimeout() {
      clearTimeout(this.hoverTimeoutId);
    },
    onMouseMove(e) {
      // add some wiggle room to the left of mouse cursor
      this.currentMouseX = Math.max(0, e.clientX - 5);
    },
  },
};
</script>

<template>
  <div
    :id="`${targetId}-flyout`"
    :style="flyoutStyle"
    class="gl-fixed gl-z-9999 -gl-mx-1 gl-max-h-full gl-overflow-y-auto"
    @mouseover="$emit('mouseover')"
    @mouseleave="$emit('mouseleave')"
  >
    <ul
      class="gl-min-w-20 gl-max-w-34 gl-list-none gl-rounded-base gl-border-1 gl-border-solid gl-border-default gl-bg-overlap gl-p-2 gl-pb-1 gl-shadow-md"
      @mouseenter="showSVG = false"
    >
      <nav-item
        v-for="item of items"
        :key="item.id"
        :item="item"
        :is-flyout="true"
        :async-count="asyncCount"
        @pin-add="(itemId, itemTitle) => $emit('pin-add', itemId, itemTitle)"
        @pin-remove="(itemId, itemTitle) => $emit('pin-remove', itemId, itemTitle)"
        @nav-link-click="$emit('nav-link-click')"
      />
    </ul>
    <svg
      v-if="targetRect && showSVG"
      :width="flyoutX"
      :height="flyoutHeight"
      viewBox="0 0 100 100"
      preserveAspectRatio="none"
      :style="{
        top: flyoutY + 'px',
      }"
    >
      <polygon
        ref="topSVG"
        :points="topSVGPoints"
        fill="transparent"
        @mouseenter="startHoverTimeout"
        @mouseleave="stopHoverTimeout"
      />
      <polygon
        ref="bottomSVG"
        :points="bottomSVGPoints"
        fill="transparent"
        @mouseenter="startHoverTimeout"
        @mouseleave="stopHoverTimeout"
      />
    </svg>
  </div>
</template>

<style scoped>
svg {
  pointer-events: none;

  position: fixed;
  right: 0;
}

svg polygon,
svg rect {
  pointer-events: auto;
}
</style>

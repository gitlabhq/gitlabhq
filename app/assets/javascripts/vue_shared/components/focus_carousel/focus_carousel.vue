<script>
import { uniqueId } from 'lodash-es';
import { GlBadge, GlButton, GlSkeletonLoader, GlSprintf } from '@gitlab/ui';
import {
  ARROW_DOWN_KEY,
  ARROW_UP_KEY,
  END_KEY,
  ENTER_KEY,
  ESC_KEY,
  HOME_KEY,
} from '~/lib/utils/keys';
import { s__, sprintf } from '~/locale';
import { visitUrl } from '~/lib/utils/url_utility';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import timeagoMixin from '~/vue_shared/mixins/timeago';

// Wheel steps are gesture-based. A flat time lock either eats quick deliberate
// gestures or double-steps a long inertial tail; instead, a step is taken only
// at a gesture boundary (a quiet gap in the stream, a rising delta, a repeated
// full-size notch, or a direction flip), and a short refractory window after
// each step absorbs that same gesture's ramp-up.
export const WHEEL_DELTA_THRESHOLD = 8;
export const WHEEL_GESTURE_GAP_MS = 140;
export const WHEEL_REFRACTORY_MS = 160;
export const WHEEL_NOTCH_MIN = 60;
const WHEEL_RISE_FACTOR = 1.4;
// Line-mode wheels (DOM_DELTA_LINE, e.g. Firefox on Windows) report deltas in
// lines, far below a pixel threshold; normalized with a nominal line height.
const WHEEL_LINE_HEIGHT = 16;
const NEXT_ITEMS_SHOWN = 2;
const REDUCED_MOTION_QUERY = `(prefers-reduced-motion: reduce)`;

/**
 * A vertical carousel built around a focused item: one item holds the stage
 * (title, meta line, summary, action) while its neighbours render as dimmed
 * rail rows, navigable by wheel, arrow keys, and click.
 *
 * Keyboard contract: the group is the widget's single composite tab stop;
 * arrows/Home/End browse from it and Enter opens the focused item's action,
 * so browse-open-browse never leaves the group. Escape from an interior stop
 * returns focus to the group. Rail rows are pointer shortcuts outside the tab
 * order, and the action is described by the focused title.
 *
 * Items are plain objects:
 * - `id` (required, unique) and `title` (required)
 * - `timestamp`: ISO string, rendered as time-ago
 * - `status`: `{ text, variant, icon }`, rendered as a badge; `variant` and
 *   `icon` take whatever `GlBadge` accepts
 * - `meta`: array of strings for the meta line
 * - `summary`: supporting copy under the meta line
 * - `href`: the action renders as a real link that owns navigation
 * - `actionable`: without an href, render the action as a button that emits
 *   `open` with the item; with neither, the item has no action affordance
 *
 * Emits `change` with the newly focused item on every navigation, and `open`
 * when the action is used on an item without an href.
 *
 * Sizing contract for embedders: give the component a real width (it is an
 * inline-size container and collapses in shrink-to-fit contexts) and a bounded
 * height; content bottom-anchors when it fits and scrolls when it cannot.
 */
export default {
  name: 'FocusCarousel',
  components: {
    GlBadge,
    GlButton,
    GlSkeletonLoader,
    GlSprintf,
    TimeAgoTooltip,
  },
  mixins: [timeagoMixin],
  props: {
    items: {
      type: Array,
      required: false,
      default: () => [],
      validator: (items) =>
        items.every((item) => item?.id != null && Boolean(item?.title)) &&
        new Set(items.map((item) => item.id)).size === items.length,
    },
    loading: {
      type: Boolean,
      required: false,
      default: false,
    },
    // The group's accessible name; the embedding surface names its content
    // ("Recent GitLab Duo sessions"), the carousel only describes itself.
    regionLabel: {
      type: String,
      required: true,
    },
    emptyStateText: {
      type: String,
      required: true,
    },
    actionLabel: {
      type: String,
      required: false,
      default: () => s__('FocusCarousel|Open'),
    },
    actionIcon: {
      type: String,
      required: false,
      default: '',
    },
    // The focused item's title participates in the page outline; the embedder
    // owns the document structure, so it picks the level.
    headingLevel: {
      type: Number,
      required: false,
      default: 3,
      validator: (level) => level >= 2 && level <= 6,
    },
  },
  emits: ['change', 'open'],
  data() {
    return {
      // The focus pointer is an id, not an index, pinned by the items watcher
      // as soon as data arrives: a refetch that inserts or removes rows must
      // not silently swap which item is focused.
      focusId: null,
      // Set only on navigation, so a background data refresh does not
      // re-announce an item the user is already reading.
      announcement: '',
      // Links the action to the focused title for assistive tech; stable per
      // instance, and the out-in transition never mounts two cards at once.
      titleId: uniqueId('focus-carousel-title-'),
      // Read once at mount: the carousel only animates through CSS transitions,
      // so the preference is not re-evaluated per interaction.
      prefersReducedMotion: window.matchMedia?.(REDUCED_MOTION_QUERY).matches ?? false,
    };
  },
  computed: {
    focusIdx() {
      const index = this.items.findIndex((item) => item.id === this.focusId);
      return index === -1 ? 0 : index;
    },
    focusItem() {
      return this.items[this.focusIdx] ?? null;
    },
    focusMeta() {
      return this.focusItem?.meta || [];
    },
    headingTag() {
      return `h${this.headingLevel}`;
    },
    showActionAffordance() {
      return Boolean(this.focusItem?.href || this.focusItem?.actionable);
    },
    prevItem() {
      return this.focusIdx > 0 ? this.items[this.focusIdx - 1] : null;
    },
    nextItems() {
      return this.items.slice(this.focusIdx + 1, this.focusIdx + 1 + NEXT_ITEMS_SHOWN);
    },
    isNavigable() {
      return this.items.length > 1;
    },
    transitionName() {
      return this.prefersReducedMotion ? null : 'fade';
    },
  },
  watch: {
    items: {
      immediate: true,
      handler(items) {
        if (items.some((item) => item.id === this.focusId)) return;

        // A pointer that no longer resolves (first data arrival, focused item
        // actioned away, list emptied) re-pins to the top, and the last
        // navigation announcement no longer describes the list.
        this.focusId = items[0]?.id ?? null;
        this.announcement = '';
        // The outgoing card may hold DOM focus (its action or date); park the
        // user on the group instead of letting focus drop to <body>.
        if (this.$el?.contains(document.activeElement)) {
          this.$nextTick(() => this.$el?.focus({ preventScroll: true }));
        }
      },
    },
  },
  created() {
    // Wheel gesture tracking; plain instance fields, nothing renders from them.
    this.lastWheel = { time: -Infinity, magnitude: 0, direction: 0 };
    this.lastWheelStep = -Infinity;
  },
  methods: {
    focusItemAt(index) {
      const clamped = Math.min(Math.max(index, 0), Math.max(this.items.length - 1, 0));
      if (clamped === this.focusIdx) return;

      this.focusId = this.items[clamped]?.id ?? null;
      this.announce(clamped);
      this.$emit('change', this.items[clamped]);
      // Rail rows vanish when promoted to the focus card, which would drop DOM
      // focus to <body>; pull it back to the group. Guarded so a wheel over an
      // unfocused carousel never steals focus from elsewhere on the page, and
      // without scrolling: focus was already inside, the widget is on screen.
      if (this.$el.contains(document.activeElement)) {
        this.$nextTick(() => this.$el?.focus({ preventScroll: true }));
      }
    },
    announce(index) {
      const item = this.items[index];
      if (!item) return;

      // Two full message forms rather than one with an optional slot, so a
      // status-less item does not read out with a dangling comma. Parameters
      // stay unescaped: the live region renders as text, and sprintf's default
      // HTML-escaping would read entities aloud.
      const message = item.status?.text
        ? this.$options.i18n.announcementWithStatus
        : this.$options.i18n.announcement;
      this.announcement = sprintf(
        message,
        {
          current: index + 1,
          total: this.items.length,
          title: item.title,
          status: item.status?.text,
        },
        false,
      );
    },
    moveFocus(delta) {
      this.focusItemAt(this.focusIdx + delta);
    },
    canMove(delta) {
      const next = this.focusIdx + delta;
      return next >= 0 && next <= this.items.length - 1;
    },
    onWheel(event) {
      // Pinch-zoom arrives as a ctrl-wheel; horizontal pans and zero-delta
      // events are not this axis. None of them may step or be claimed.
      if (event.ctrlKey || event.metaKey) return;
      if (event.deltaY === 0 || Math.abs(event.deltaX) > Math.abs(event.deltaY)) return;

      const lineMode = event.deltaMode !== WheelEvent.DOM_DELTA_PIXEL;
      const deltaY = lineMode ? event.deltaY * WHEEL_LINE_HEIGHT : event.deltaY;
      const magnitude = Math.abs(deltaY);
      const direction = deltaY > 0 ? 1 : -1;
      const now = performance.now();
      const previous = this.lastWheel;
      // Every event extends the stream, including sub-threshold inertia dregs,
      // so a trailing gap is measured against the true end of the gesture.
      this.lastWheel = { time: now, magnitude, direction };

      if (magnitude < WHEEL_DELTA_THRESHOLD) return;
      // Let the wheel fall through to the page at either end of the list, so
      // the carousel never traps a scroll it cannot consume.
      if (!this.canMove(direction)) return;

      // A flip can never be the stepping gesture's own ramp, so it bypasses
      // the refractory; the rise test is floored at the threshold so
      // sub-threshold dregs cannot turn tail jitter into a new push. Line-mode
      // wheels are discrete by construction, so every repeat is a notch there.
      const directionFlipped = previous.direction !== 0 && direction !== previous.direction;
      const riseBase = Math.max(previous.magnitude, WHEEL_DELTA_THRESHOLD);
      const newGesture =
        directionFlipped ||
        now - previous.time > WHEEL_GESTURE_GAP_MS ||
        magnitude >= riseBase * WHEEL_RISE_FACTOR ||
        ((lineMode || magnitude >= WHEEL_NOTCH_MIN) && magnitude >= previous.magnitude);

      if (!newGesture) return;
      // Non-stepping events are not claimed, so they fall through wherever
      // the page itself scrolls.
      if (!directionFlipped && now - this.lastWheelStep < WHEEL_REFRACTORY_MS) return;

      event.preventDefault();
      this.lastWheelStep = now;
      this.moveFocus(direction);
    },
    onKeydown(event) {
      if (event.ctrlKey || event.metaKey || event.altKey || event.shiftKey) return;

      // Escape backs focus out of the card's interior stops to the group (the
      // grid-pattern exit), so in-and-out never needs Shift+Tab counting. Only
      // while the group is focusable: a single-item group has no tab stop to
      // return to, and a claimed no-op would rob the surface above.
      if (event.key === ESC_KEY && event.target !== this.$el) {
        if (!this.isNavigable) return;

        event.preventDefault();
        this.$el.focus({ preventScroll: true });
        return;
      }

      // Other keys operate the widget only from its own tab stop: a bubbled
      // keydown from the action or the date would navigate the carousel out
      // from under the element the user is standing on.
      if (event.target !== this.$el) return;

      switch (event.key) {
        case ENTER_KEY:
          if (!this.showActionAffordance) break;
          event.preventDefault();
          this.activateFocusItem();
          break;
        case ARROW_UP_KEY:
          event.preventDefault();
          this.moveFocus(-1);
          break;
        case ARROW_DOWN_KEY:
          event.preventDefault();
          this.moveFocus(1);
          break;
        case HOME_KEY:
          event.preventDefault();
          this.focusItemAt(0);
          break;
        case END_KEY:
          event.preventDefault();
          this.focusItemAt(this.items.length - 1);
          break;
        default:
      }
    },
    onOpen() {
      // Items carrying an href navigate through the action's own link; the
      // rest are the embedding surface's to resolve.
      if (this.focusItem.href) return;

      this.$emit('open', this.focusItem);
    },
    activateFocusItem() {
      // Navigate from state, never through the rendered link: during the
      // out-in swap the action's ref is unregistered or still bound to the
      // outgoing card, so a click would be dropped or open the wrong item.
      if (this.focusItem.href) {
        visitUrl(this.focusItem.href);
        return;
      }
      this.onOpen();
    },
  },
  i18n: {
    roleDescription: s__('FocusCarousel|carousel'),
    upNext: s__('FocusCarousel|Up next'),
    counter: s__('FocusCarousel|%{current} of %{total}'),
    announcement: s__('FocusCarousel|Item %{current} of %{total}: %{title}'),
    announcementWithStatus: s__('FocusCarousel|Item %{current} of %{total}: %{title}, %{status}'),
  },
};
</script>

<template>
  <div
    role="group"
    :aria-label="regionLabel"
    :aria-roledescription="isNavigable ? $options.i18n.roleDescription : null"
    :tabindex="isNavigable ? 0 : null"
    :aria-busy="loading ? 'true' : null"
    class="focus-carousel gl-flex gl-h-full gl-flex-col gl-overflow-y-auto gl-px-2"
    :class="{ 'gl-items-center gl-justify-center': !focusItem && !loading }"
    data-testid="focus-carousel"
    @wheel="onWheel"
    @keydown="onKeydown"
  >
    <span
      class="gl-sr-only"
      aria-live="polite"
      aria-atomic="true"
      data-testid="focus-carousel-announcement"
      >{{ announcement }}</span
    >

    <!-- Bottom-anchors the content when it fits; unlike justify-end, the
         auto margin collapses when it does not, so over-height content stays
         reachable through the root's own scroll. -->
    <div v-if="focusItem || loading" class="gl-mt-auto" data-testid="focus-carousel-anchor"></div>

    <div v-if="loading && !focusItem" class="gl-w-full" data-testid="focus-carousel-loading">
      <gl-skeleton-loader :lines="3" />
    </div>

    <p v-else-if="!focusItem" class="gl-m-0 gl-text-subtle" data-testid="focus-carousel-empty">
      {{ emptyStateText }}
    </p>

    <template v-else>
      <!-- Rail rows are pointer shortcuts: out of the tab order (arrows are the
           keyboard path) and title-first in the DOM so their accessible name
           leads with the title; the column reverses back to the visual order. -->
      <button
        v-if="prevItem"
        type="button"
        tabindex="-1"
        class="focus-carousel-rail-row gl-mb-8 gl-flex gl-w-full gl-flex-col-reverse gl-border-0 gl-border-l-2 gl-border-subtle gl-bg-transparent gl-py-0 gl-pl-5 gl-text-left gl-border-l-solid"
        data-testid="focus-carousel-prev"
        @click="moveFocus(-1)"
      >
        <span class="focus-carousel-rail-title gl-line-clamp-2 gl-block">{{ prevItem.title }}</span>
        <time
          v-if="prevItem.timestamp"
          :datetime="prevItem.timestamp"
          class="gl-mb-2 gl-block gl-text-sm gl-text-subtle"
          >{{ timeFormatted(prevItem.timestamp) }}</time
        >
      </button>

      <!-- The stage carries the keyboard-focus ring (activedescendant-style:
           DOM focus stays on the group, the indicator marks the current item,
           which is also exactly what Enter opens). Stable wrapper, so the
           ring survives the out-in swap of the keyed card. -->
      <div class="focus-carousel-stage">
        <transition :name="transitionName" :css="!prefersReducedMotion" mode="out-in">
          <div :key="focusItem.id" data-testid="focus-carousel-focus">
            <component
              :is="headingTag"
              :id="titleId"
              class="focus-carousel-item-title gl-my-0 -gl-mb-2 gl-line-clamp-2 gl-max-w-75 gl-pb-2"
            >
              {{ focusItem.title }}
            </component>

            <div
              class="gl-mt-3 gl-flex gl-flex-wrap gl-items-center gl-gap-2 gl-text-sm gl-text-subtle"
            >
              <template v-if="focusItem.status">
                <gl-badge
                  :variant="focusItem.status.variant"
                  :icon="focusItem.status.icon"
                  data-testid="focus-carousel-status"
                  >{{ focusItem.status.text }}</gl-badge
                >
                <span v-if="focusItem.timestamp" aria-hidden="true">&middot;</span>
              </template>
              <time-ago-tooltip v-if="focusItem.timestamp" :time="focusItem.timestamp" />
              <span
                v-for="(entry, index) in focusMeta"
                :key="`meta-${index}`"
                class="gl-flex gl-items-center gl-gap-2"
              >
                <span v-if="index > 0 || focusItem.timestamp || focusItem.status" aria-hidden="true"
                  >&middot;</span
                >
                <span data-testid="focus-carousel-meta">{{ entry }}</span>
              </span>
            </div>

            <p
              v-if="focusItem.summary"
              class="gl-mt-5 gl-line-clamp-3 gl-max-w-62 gl-text-default"
              data-testid="focus-carousel-summary"
            >
              {{ focusItem.summary }}
            </p>

            <div v-if="showActionAffordance" class="gl-mt-6">
              <gl-button
                category="secondary"
                variant="default"
                :icon="actionIcon"
                :href="focusItem.href || undefined"
                :aria-describedby="titleId"
                data-testid="focus-carousel-open"
                @click="onOpen"
                >{{ actionLabel }}</gl-button
              >
            </div>
          </div>
        </transition>
      </div>

      <div v-if="isNavigable" class="gl-mt-12">
        <span
          v-if="nextItems.length"
          class="gl-block gl-text-xs gl-font-semibold gl-uppercase gl-tracking-wider gl-text-subtle"
          >{{ $options.i18n.upNext }}</span
        >

        <transition :name="transitionName" :css="!prefersReducedMotion" mode="out-in">
          <ul
            v-if="nextItems.length"
            :key="focusItem.id"
            class="gl-m-0 gl-mt-5 gl-flex gl-list-none gl-flex-col gl-gap-5 gl-p-0"
          >
            <li v-for="(item, index) in nextItems" :key="item.id">
              <button
                type="button"
                tabindex="-1"
                class="focus-carousel-rail-row gl-flex gl-w-full gl-flex-col-reverse gl-border-0 gl-border-l-2 gl-border-subtle gl-bg-transparent gl-py-0 gl-pl-5 gl-text-left gl-border-l-solid"
                data-testid="focus-carousel-next-item"
                @click="moveFocus(index + 1)"
              >
                <span class="focus-carousel-rail-title gl-line-clamp-2 gl-block">{{
                  item.title
                }}</span>
                <time
                  v-if="item.timestamp"
                  :datetime="item.timestamp"
                  class="gl-mb-2 gl-block gl-text-sm gl-text-subtle"
                  >{{ timeFormatted(item.timestamp) }}</time
                >
              </button>
            </li>
          </ul>
        </transition>

        <!-- Last block in the bottom-anchored column, so the counter's offset
             from the container's bottom edge never depends on how many rail
             rows are above it. -->
        <span
          class="gl-mt-5 gl-block gl-text-right gl-text-sm gl-tabular-nums gl-text-subtle"
          data-testid="focus-carousel-counter"
        >
          <gl-sprintf :message="$options.i18n.counter">
            <template #current>{{ focusIdx + 1 }}</template>
            <template #total>{{ items.length }}</template>
          </gl-sprintf>
        </span>
      </div>
    </template>
  </div>
</template>

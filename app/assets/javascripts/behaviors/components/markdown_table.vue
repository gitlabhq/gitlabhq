<script>
import { GlButton, GlIcon, GlResizeObserverDirective, GlTooltip } from '@gitlab/ui';
import { uniqueId } from 'lodash-es';
import {
  MARKDOWN_TABLE_EXPANDED_EVENT,
  MARKDOWN_TABLE_EXPANDED_KEY,
} from '~/behaviors/markdown/constants';
import AccessorUtilities from '~/lib/utils/accessor';
import { getStorageValue, saveStorageValue } from '~/lib/utils/local_storage';
import { getScrollingElement } from '~/lib/utils/panels';
import {
  STICKY_HEADER_CLASSES,
  STICKY_HEADER_MAX_HEIGHT_CLASS,
  STICKY_HEADER_MAX_HEIGHT_VH,
} from '~/lib/utils/table_sticky_header';
import { s__, sprintf } from '~/locale';
import { InternalEvents } from '~/tracking';

const ASCENDING = 'ascending';
const DESCENDING = 'descending';

const SORT_ACTIONS = {
  ascending: { icon: 'sort-lowest', label: s__('Table|Sort ascending') },
  descending: { icon: 'sort-highest', label: s__('Table|Sort descending') },
  reset: { icon: 'redo', label: s__('Table|Reset sorting') },
};

function isEmpty(value) {
  return value === '';
}

function readStoredExpanded() {
  if (!AccessorUtilities.canUseLocalStorage()) return false;

  const { exists, value } = getStorageValue(MARKDOWN_TABLE_EXPANDED_KEY);
  return exists && value === true;
}

const adopt = (el, { value, oldValue }) => {
  if (value === oldValue) return;

  const nodes = Array.isArray(value) ? value : Array.from(value.childNodes);

  el.textContent = '';
  nodes.forEach((node) => el.appendChild(node));
};

// `bind`/`update` are the Vue 2 hook names, which @vue/compat maps to their Vue 3
// equivalents; ~/vue_shared/directives/safe_html.js does the same.
const adoptDirective = { bind: adopt, update: adopt };

export default {
  name: 'MarkdownTable',
  components: {
    GlButton,
    GlIcon,
    GlTooltip,
  },
  directives: {
    adoptCells: adoptDirective,
    adoptContent: adoptDirective,
    GlResizeObserver: GlResizeObserverDirective,
  },
  mixins: [InternalEvents.mixin()],
  props: {
    fields: {
      type: Array,
      required: false,
      default: () => [],
    },
    headRows: {
      type: Array,
      required: false,
      default: () => [],
    },
    bodies: {
      type: Array,
      required: false,
      default: () => [],
    },
    footerRows: {
      type: Array,
      required: false,
      default: () => [],
    },
    caption: {
      type: HTMLElement,
      required: false,
      default: null,
    },
    tableAttributes: {
      type: Object,
      required: false,
      default: () => ({}),
    },
    dir: {
      type: String,
      required: false,
      default: null,
    },
  },
  data() {
    return {
      tableId: uniqueId('markdown-table-'),
      interactiveHeaderKeys: this.fields
        .filter(({ cell }) => cell.querySelector('a, button, input, select, textarea, [tabindex]'))
        .map(({ key }) => key),
      emptyHeaderKeys: this.fields
        .filter(({ cell }) => !cell.textContent.trim())
        .map(({ key }) => key),
      columnNames: Object.fromEntries(
        this.fields.map(({ key, cell }, index) => [
          key,
          cell.textContent.trim() ||
            sprintf(s__('Table|Column %{columnNumber}'), { columnNumber: index + 1 }),
        ]),
      ),
      hasSorted: false,
      sortKey: null,
      sortDirection: ASCENDING,
      visibleTooltipKeys: [],
      isExpanded: readStoredExpanded(),
      isClipped: false,
    };
  },
  computed: {
    stickyHeaderClasses() {
      return this.isExpanded
        ? STICKY_HEADER_CLASSES
        : [STICKY_HEADER_MAX_HEIGHT_CLASS, ...STICKY_HEADER_CLASSES];
    },
    toggleExpandedLabel() {
      return this.isExpanded ? s__('Table|Collapse table') : s__('Table|Show full table');
    },
    canSort() {
      return this.fields.length > 0;
    },
    sortAnnouncement() {
      if (!this.hasSorted) return '';
      if (this.sortKey === null) return s__('Table|Original row order restored.');

      return sprintf(
        this.sortDirection === ASCENDING
          ? s__('Table|%{columnName} sorted ascending.')
          : s__('Table|%{columnName} sorted descending.'),
        { columnName: this.columnNames[this.sortKey] },
        false,
      );
    },
    sortedBodies() {
      if (!this.sortKey) {
        return this.bodies;
      }
      const key = this.sortKey;
      const ascending = this.sortDirection === ASCENDING;
      const [items] = this.bodies;

      const sorted = [...items].sort((rowA, rowB) => {
        const a = rowA[key]?.text ?? '';
        const b = rowB[key]?.text ?? '';

        // Empty cells always sort to the end, regardless of sort direction.
        if (isEmpty(a) && isEmpty(b)) return 0;
        if (isEmpty(a)) return 1;
        if (isEmpty(b)) return -1;

        const comparison = a.toLowerCase().localeCompare(b.toLowerCase());
        return ascending ? comparison : -comparison;
      });

      return [sorted];
    },
  },
  mounted() {
    window.addEventListener(MARKDOWN_TABLE_EXPANDED_EVENT, this.onExpandedChange);
    window.addEventListener('resize', this.scheduleUpdateClipped);
  },
  beforeDestroy() {
    window.removeEventListener(MARKDOWN_TABLE_EXPANDED_EVENT, this.onExpandedChange);
    window.removeEventListener('resize', this.scheduleUpdateClipped);
    cancelAnimationFrame(this.clippedFrame);
  },
  methods: {
    async toggleExpanded() {
      const isExpanded = !this.isExpanded;
      const anchor = isExpanded ? this.$el : this.$refs.heightToggle.$el;
      const anchorTop = anchor.getBoundingClientRect().top;

      if (AccessorUtilities.canUseLocalStorage()) {
        saveStorageValue(MARKDOWN_TABLE_EXPANDED_KEY, isExpanded);
      }

      window.dispatchEvent(
        new CustomEvent(MARKDOWN_TABLE_EXPANDED_EVENT, { detail: { isExpanded } }),
      );

      this.trackEvent('toggle_markdown_table_full_height', {
        property: isExpanded ? 'expanded' : 'collapsed',
      });

      await this.$nextTick();
      getScrollingElement(anchor).scrollBy({
        top: anchor.getBoundingClientRect().top - anchorTop,
      });
    },
    onExpandedChange({ detail }) {
      this.isExpanded = detail.isExpanded;
    },
    scheduleUpdateClipped() {
      cancelAnimationFrame(this.clippedFrame);
      this.clippedFrame = requestAnimationFrame(this.updateClipped);
    },
    updateClipped() {
      this.isClipped =
        this.$refs.table.offsetHeight > (window.innerHeight * STICKY_HEADER_MAX_HEIGHT_VH) / 100;
    },
    headerAlign({ cell }) {
      return cell.getAttribute('align');
    },
    headerStyle({ cell }) {
      return cell.getAttribute('style');
    },
    ariaSort(key) {
      if (this.sortKey !== key) return 'none';
      return this.sortDirection;
    },
    nextSortAction(key) {
      if (this.sortKey !== key) return SORT_ACTIONS.ascending;
      return this.sortDirection === ASCENDING ? SORT_ACTIONS.descending : SORT_ACTIONS.reset;
    },
    showTooltip(key) {
      this.visibleTooltipKeys.push(key);
    },
    hideTooltip(key) {
      this.visibleTooltipKeys = this.visibleTooltipKeys.filter((visibleKey) => visibleKey !== key);
    },
    handleSort(key) {
      this.hasSorted = true;
      if (this.sortKey === key) {
        if (this.sortDirection === DESCENDING) {
          this.sortKey = null;
          return;
        }
        this.sortDirection = DESCENDING;
      } else {
        this.sortKey = key;
        this.sortDirection = ASCENDING;
      }

      this.trackEvent('sort_markdown_table_column', {
        property: this.sortDirection,
      });
    },
  },
};
</script>
<template>
  <div
    class="gl-my-5 gl-w-fit gl-max-w-full [&:has(>.gl-table-shadow-overlay:dir(rtl))]:gl-ml-auto"
  >
    <!--
    The toggle sits outside the shadow overlay so the overlay's border and
    bottom scroll shadow keep framing the table itself.
    -->
    <div data-testid="table-shadow-overlay" class="gl-table-shadow-overlay" :dir="dir">
      <!--
      Print scale-to-fit (wikis/utils/print_table_scale.js) measures
      `[data-print-scale-target]` against `[data-print-scale-container]`, which
      is the sticky-header wrapper that scrolls on screen.
    -->
      <div
        :id="`${tableId}-scroll`"
        :class="stickyHeaderClasses"
        data-sticky-header
        data-print-scale-container
      >
        <table
          ref="table"
          v-gl-resize-observer="scheduleUpdateClipped"
          v-bind="tableAttributes"
          data-markdown-table-applied="true"
          data-print-scale-target
          class="gl-min-w-full gl-overflow-y-hidden"
        >
          <caption v-if="caption" v-adopt-content="caption"></caption>
          <thead v-if="canSort || headRows.length">
            <tr v-if="canSort">
              <th
                v-for="field in fields"
                :key="field.key"
                :align="headerAlign(field)"
                :style="headerStyle(field)"
                :aria-sort="ariaSort(field.key)"
                :aria-labelledby="
                  interactiveHeaderKeys.includes(field.key) ? `${tableId}-${field.key}` : null
                "
                scope="col"
                class="gl-group/markdown-table-header"
              >
                <div class="gl-flex gl-items-center gl-gap-2">
                  <span
                    v-if="interactiveHeaderKeys.includes(field.key)"
                    :id="`${tableId}-${field.key}`"
                    v-adopt-content="field.cell"
                    class="gl-relative gl-z-1"
                  ></span>
                  <button
                    :id="`${tableId}-${field.key}-sort`"
                    type="button"
                    class="gl-group gl-flex gl-cursor-pointer gl-items-center gl-gap-2 gl-border-0 gl-bg-transparent gl-p-0 gl-text-left gl-font-bold gl-text-inherit focus-visible:gl-outline-none"
                    :aria-labelledby="
                      interactiveHeaderKeys.includes(field.key) ? `${tableId}-${field.key}` : null
                    "
                    :aria-label="
                      emptyHeaderKeys.includes(field.key) ? columnNames[field.key] : null
                    "
                    @click="handleSort(field.key)"
                  >
                    <span
                      aria-hidden="true"
                      class="gl-absolute gl-inset-0 group-focus-visible:gl-focus-inset"
                    ></span>
                    <span
                      v-if="!interactiveHeaderKeys.includes(field.key)"
                      v-adopt-content="field.cell"
                    ></span>
                    <gl-icon
                      :name="nextSortAction(field.key).icon"
                      class="gl-shrink-0 group-hover/markdown-table-header:gl-opacity-10 group-focus-visible:gl-opacity-10"
                      :class="
                        visibleTooltipKeys.includes(field.key) ? 'gl-opacity-10' : 'gl-opacity-0'
                      "
                      data-sort-icon
                    />
                  </button>
                  <gl-tooltip
                    :target="`${tableId}-${field.key}-sort`"
                    @show="showTooltip(field.key)"
                    @hidden="hideTooltip(field.key)"
                  >
                    {{ nextSortAction(field.key).label }}
                  </gl-tooltip>
                </div>
              </th>
            </tr>
            <tr v-for="(cells, index) in headRows" :key="index" v-adopt-cells="cells"></tr>
          </thead>
          <tbody v-for="(items, index) in sortedBodies" :key="index">
            <tr v-for="item in items" :key="item.rowIndex" v-adopt-cells="item.cells"></tr>
          </tbody>
          <tfoot v-if="footerRows.length">
            <tr v-for="(cells, index) in footerRows" :key="index" v-adopt-cells="cells"></tr>
          </tfoot>
        </table>
      </div>
    </div>
    <div v-if="isClipped" class="gl-mt-2 gl-flex gl-justify-center print:gl-hidden">
      <gl-button
        ref="heightToggle"
        category="tertiary"
        size="small"
        :icon="isExpanded ? 'collapse' : 'expand'"
        :aria-expanded="String(isExpanded)"
        :aria-controls="`${tableId}-scroll`"
        data-testid="markdown-table-height-toggle"
        @click="toggleExpanded"
      >
        {{ toggleExpandedLabel }}
      </gl-button>
    </div>
    <div v-if="canSort" class="gl-sr-only" role="status" aria-live="polite" aria-atomic="true">
      <span :key="`${sortKey}-${sortDirection}`">{{ sortAnnouncement }}</span>
    </div>
  </div>
</template>

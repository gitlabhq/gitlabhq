<script>
import { GlIcon, GlTooltip } from '@gitlab/ui';
import { uniqueId } from 'lodash-es';
import {
  STICKY_HEADER_CLASSES,
  STICKY_TABLE_WRAPPER_CLASSES,
} from '~/lib/utils/table_sticky_header';
import { s__, sprintf } from '~/locale';
import { InternalEvents } from '~/tracking';

const ASCENDING = 'ascending';
const DESCENDING = 'descending';
// Performance limit: disable sorting for tables with more than 1000 rows.
const MAX_SORTABLE_ROWS = 1000;

const SORT_ACTIONS = {
  ascending: { icon: 'sort-lowest', label: s__('Table|Sort ascending') },
  descending: { icon: 'sort-highest', label: s__('Table|Sort descending') },
  reset: { icon: 'redo', label: s__('Table|Reset sorting') },
};

function isEmpty(value) {
  return value === '';
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
    GlIcon,
    GlTooltip,
  },
  directives: {
    adoptCells: adoptDirective,
    adoptContent: adoptDirective,
  },
  mixins: [InternalEvents.mixin()],
  stickyHeaderClasses: STICKY_HEADER_CLASSES,
  stickyTableWrapperClasses: STICKY_TABLE_WRAPPER_CLASSES,
  props: {
    // Header cells. Each field is `{ key, cell }`, where `cell` is the header cell
    // element.
    fields: {
      type: Array,
      required: false,
      default: () => [],
    },
    // Body rows. Each item is `{ cells, rowIndex }` plus, per field `key`,
    // a `{ text }` used for sorting comparisons.
    items: {
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
    };
  },
  computed: {
    canSort() {
      return this.items.length <= MAX_SORTABLE_ROWS && this.items.length > 1;
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
    sortedItems() {
      if (!this.canSort || !this.sortKey) {
        return this.items;
      }
      const key = this.sortKey;
      const ascending = this.sortDirection === ASCENDING;

      return [...this.items].sort((rowA, rowB) => {
        const a = rowA[key]?.text ?? '';
        const b = rowB[key]?.text ?? '';

        // Empty cells always sort to the end, regardless of sort direction.
        if (isEmpty(a) && isEmpty(b)) return 0;
        if (isEmpty(a)) return 1;
        if (isEmpty(b)) return -1;

        const comparison = a.toLowerCase().localeCompare(b.toLowerCase());
        return ascending ? comparison : -comparison;
      });
    },
  },
  methods: {
    headerAlign({ cell }) {
      return cell.getAttribute('align');
    },
    headerStyle({ cell }) {
      return cell.getAttribute('style');
    },
    ariaSort(key) {
      if (!this.canSort) return null;
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
      if (!this.canSort) return;

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
  <div data-testid="table-shadow-overlay" :class="$options.stickyTableWrapperClasses">
    <!--
    Print scale-to-fit (wikis/utils/print_table_scale.js) measures
    `[data-print-scale-target]` against `[data-print-scale-container]`, which
    is the sticky-header wrapper that scrolls on screen.
  -->
    <div :class="$options.stickyHeaderClasses" data-sticky-header data-print-scale-container>
      <table
        data-markdown-table-applied="true"
        data-print-scale-target
        class="gl-min-w-full gl-overflow-y-hidden"
      >
        <caption v-if="caption" v-adopt-content="caption"></caption>
        <thead>
          <tr>
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
                  v-if="!canSort || interactiveHeaderKeys.includes(field.key)"
                  :id="`${tableId}-${field.key}`"
                  v-adopt-content="field.cell"
                  :class="{ 'gl-relative gl-z-1': canSort }"
                ></span>
                <button
                  v-if="canSort"
                  :id="`${tableId}-${field.key}-sort`"
                  type="button"
                  class="gl-group gl-flex gl-cursor-pointer gl-items-center gl-gap-2 gl-border-0 gl-bg-transparent gl-p-0 gl-text-left gl-font-bold gl-text-inherit focus-visible:gl-outline-none"
                  :aria-labelledby="
                    interactiveHeaderKeys.includes(field.key) ? `${tableId}-${field.key}` : null
                  "
                  :aria-label="emptyHeaderKeys.includes(field.key) ? columnNames[field.key] : null"
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
                  v-if="canSort"
                  :target="`${tableId}-${field.key}-sort`"
                  @show="showTooltip(field.key)"
                  @hidden="hideTooltip(field.key)"
                >
                  {{ nextSortAction(field.key).label }}
                </gl-tooltip>
              </div>
            </th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="item in sortedItems" :key="item.rowIndex" v-adopt-cells="item.cells"></tr>
        </tbody>
        <tfoot v-if="footerRows.length">
          <tr v-for="(cells, index) in footerRows" :key="index" v-adopt-cells="cells"></tr>
        </tfoot>
      </table>
    </div>
    <div v-if="canSort" class="gl-sr-only" role="status" aria-live="polite" aria-atomic="true">
      <span :key="`${sortKey}-${sortDirection}`">{{ sortAnnouncement }}</span>
    </div>
  </div>
</template>

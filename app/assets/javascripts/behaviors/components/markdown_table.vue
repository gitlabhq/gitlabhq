<script>
import {
  STICKY_HEADER_CLASSES,
  STICKY_TABLE_WRAPPER_CLASSES,
} from '~/lib/utils/table_sticky_header';
import { s__ } from '~/locale';

const ASCENDING = 'ascending';
const DESCENDING = 'descending';
const SORT_ARROWS = { [ASCENDING]: '↑', [DESCENDING]: '↓' };
// Performance limit: disable sorting for tables with more than 1000 rows.
const MAX_SORTABLE_ROWS = 1000;

function isEmpty(value) {
  return value === '';
}

// Move the rendered cells into the table we render, rather than rebuilding it, so
// that whatever is already attached to them (popovers, lightbox handlers, Mermaid
// diagrams iframes) comes along with them.
//
// The value is either the nodes to adopt, or the element to adopt the children of.
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
  directives: {
    // On a <tr>: the row's own <td>/<th> elements, attributes and all.
    adoptCells: adoptDirective,
    // On a <span>: the child nodes of a header cell, whose <th> we render ourselves.
    adoptContent: adoptDirective,
  },
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
    isSortable: {
      type: Boolean,
      required: false,
      default: false,
    },
    isSticky: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    return {
      sortKey: null,
      sortDirection: ASCENDING,
    };
  },
  computed: {
    canSort() {
      return this.isSortable && this.items.length <= MAX_SORTABLE_ROWS && this.items.length > 1;
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
    // We render the <th> ourselves, so the source cell's alignment has to be applied
    // to it: GLFM renders pipe tables with `align`, but `text-align` styles are also
    // permitted, so we have to preserve either/both!
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
    sortIcon(key) {
      if (this.sortKey !== key) return '';
      return SORT_ARROWS[this.sortDirection];
    },
    srOnlyText(key) {
      if (this.sortKey === key && this.sortDirection === ASCENDING) {
        return s__('Table|Click to sort descending');
      }
      return s__('Table|Click to sort ascending');
    },
    handleSort(key) {
      if (!this.canSort) return;

      if (this.sortKey === key) {
        this.sortDirection = this.sortDirection === ASCENDING ? DESCENDING : ASCENDING;
      } else {
        this.sortKey = key;
        this.sortDirection = ASCENDING;
      }
    },
  },
};
</script>
<template>
  <div
    :data-testid="isSticky ? 'table-shadow-overlay' : null"
    :class="isSticky ? $options.stickyTableWrapperClasses : ''"
  >
    <!--
    Print scale-to-fit (wikis/utils/print_table_scale.js) measures
    `[data-print-scale-target]` against `[data-print-scale-container]`, which
    should be the element that scrolls on screen; when sticky headers are enabled,
    this is the wrapper, otherwise it's the table itself.
  -->
    <div
      :class="isSticky ? $options.stickyHeaderClasses : ''"
      :data-sticky-header="isSticky || null"
      :data-print-scale-container="isSticky || null"
    >
      <table
        :data-print-scale-container="isSticky ? null : ''"
        data-print-scale-target
        :class="{ 'gl-my-5': !isSticky }"
        class="gl-min-w-full gl-overflow-y-hidden"
      >
        <thead>
          <tr>
            <th
              v-for="field in fields"
              :key="field.key"
              :align="headerAlign(field)"
              :style="headerStyle(field)"
              :aria-sort="ariaSort(field.key)"
              :tabindex="canSort ? '0' : null"
              :class="{ 'gl-cursor-pointer': canSort }"
              @click="handleSort(field.key)"
              @keydown.enter.prevent="handleSort(field.key)"
              @keydown.space.prevent="handleSort(field.key)"
            >
              <div class="gl-flex">
                <span v-adopt-content="field.cell"></span>
                <template v-if="canSort">
                  <div
                    class="gl-table-th-sort-icon-wrapper gl-ml-2 gl-flex gl-w-5 gl-justify-center"
                  >
                    <span data-sort-icon>{{ sortIcon(field.key) }}</span>
                  </div>
                  <span class="gl-sr-only">{{ srOnlyText(field.key) }}</span>
                </template>
              </div>
            </th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="item in sortedItems" :key="item.rowIndex" v-adopt-cells="item.cells"></tr>
        </tbody>
      </table>
    </div>
  </div>
</template>

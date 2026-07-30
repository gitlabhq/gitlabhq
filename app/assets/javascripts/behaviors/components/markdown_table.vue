<script>
import { STICKY_HEADER_CLASSES } from '~/lib/utils/table_sticky_header';
import { s__ } from '~/locale';

const ASCENDING = 'ascending';
const DESCENDING = 'descending';

const SORT_ARROWS = { [ASCENDING]: '↑', [DESCENDING]: '↓' };

// Performance limit: disable sorting for tables with more than 1000 rows.
const MAX_SORTABLE_ROWS = 1000;

function isEmpty(value) {
  return value === '';
}

export default {
  name: 'MarkdownTable',
  stickyHeaderClasses: STICKY_HEADER_CLASSES,
  props: {
    // Parsed header cells. Each field is `{ key, label }` where `label` is the
    // rendered markdown HTML for the header cell.
    fields: {
      type: Array,
      required: false,
      default: () => [],
    },
    // Parsed body rows. Each item maps a field `key` to `{ html, text, rowIndex }`, where
    // `html` preserves the rendered markdown and `text` is used for sorting.
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
  <!--
    Print scale-to-fit (wikis/utils/print_table_scale.js) measures
    `[data-print-scale-target]` against `[data-print-scale-container]`, which
    should be the element that scrolls on screen; when sticky headers are enabled,
    this is the wrapper, otherwise it's the table itself.
  -->
  <div
    :data-sticky-header="isSticky || null"
    :data-print-scale-container="isSticky || null"
    :class="isSticky ? $options.stickyHeaderClasses : ''"
  >
    <table
      class="!gl-my-0 gl-min-w-full gl-overflow-y-hidden"
      data-print-scale-target
      :data-print-scale-container="isSticky ? null : ''"
    >
      <thead>
        <tr>
          <th
            v-for="field in fields"
            :key="field.key"
            :aria-sort="ariaSort(field.key)"
            :tabindex="canSort ? '0' : null"
            :class="{ 'gl-cursor-pointer': canSort }"
            @click="handleSort(field.key)"
            @keydown.enter.prevent="handleSort(field.key)"
            @keydown.space.prevent="handleSort(field.key)"
          >
            <div class="gl-flex">
              <!-- eslint-disable-next-line vue/no-v-html -->
              <span v-html="field.label"></span>
              <template v-if="canSort">
                <div class="gl-table-th-sort-icon-wrapper gl-ml-2 gl-flex gl-w-5 gl-justify-center">
                  <span data-sort-icon>{{ sortIcon(field.key) }}</span>
                </div>
                <span class="gl-sr-only">{{ srOnlyText(field.key) }}</span>
              </template>
            </div>
          </th>
        </tr>
      </thead>
      <tbody>
        <tr v-for="item in sortedItems" :key="item.rowIndex">
          <td v-for="field in fields" :key="field.key">
            <!-- eslint-disable-next-line vue/no-v-html -->
            <span v-html="item[field.key] && item[field.key].html"></span>
          </td>
        </tr>
      </tbody>
    </table>
  </div>
</template>

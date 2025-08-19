<script>
import { GlIcon, GlSkeletonLoader } from '@gitlab/ui';
import { sortBy } from '../../core/sorter';
import ThResizable from '../common/th_resizable.vue';
import FieldPresenter from './field.vue';

const DEFAULT_PAGE_SIZE = 5;

export default {
  name: 'TablePresenter',
  components: {
    GlIcon,
    GlSkeletonLoader,
    ThResizable,
    FieldPresenter,
  },
  props: {
    data: {
      required: false,
      type: Object,
      default: () => ({ nodes: [] }),
    },
    fields: {
      required: false,
      type: Array,
      default: () => [],
    },
    loading: {
      required: false,
      type: [Boolean, Number],
      default: false,
    },
  },
  data() {
    return {
      items: this.data.nodes.slice(),
      sortOptions: { fieldName: null, ascending: true },
    };
  },
  computed: {
    pageSize() {
      return typeof this.loading === 'number' ? this.loading : DEFAULT_PAGE_SIZE;
    },
  },
  watch: {
    data() {
      this.items = this.data.nodes.slice();
    },
  },
  methods: {
    sortBy(fieldName) {
      const { options, items } = sortBy(this.items, fieldName, this.sortOptions);
      this.items = items;
      this.sortOptions = options;
    },
  },
};
</script>
<template>
  <div class="gl-table-shadow">
    <table class="!gl-my-0 gl-overflow-y-hidden">
      <thead class="!gl-border-b !gl-border-section gl-text-sm">
        <tr>
          <th-resizable
            v-for="(field, fieldIndex) in fields"
            :key="field.key"
            class="gl-relative !gl-border-section !gl-bg-subtle !gl-p-0 !gl-text-subtle gl-text-subtle dark:!gl-bg-strong"
          >
            <div
              :data-testid="`column-${fieldIndex}`"
              class="gl-l-0 gl-r-0 gl-absolute gl-w-full gl-cursor-pointer gl-truncate gl-px-5 gl-py-3 hover:gl-bg-strong dark:hover:gl-bg-neutral-700"
              @click="sortBy(field.key)"
            >
              <gl-icon
                v-if="sortOptions.fieldName === field.key"
                :name="sortOptions.ascending ? 'arrow-up' : 'arrow-down'"
              />
              {{ field.label }}
            </div>
            <div class="gl-pointer-events-none gl-py-3">&nbsp;</div>
          </th-resizable>
        </tr>
      </thead>
      <tbody>
        <tr
          v-for="(item, itemIndex) in items"
          :key="item.id"
          :data-testid="`table-row-${itemIndex}`"
        >
          <td
            v-for="field in fields"
            :key="field.key"
            class="!gl-border-l-0 !gl-border-r-0 !gl-border-section gl-bg-subtle !gl-px-5 !gl-py-3"
          >
            <field-presenter :item="item" :field-key="field.key" />
          </td>
        </tr>
        <template v-if="loading">
          <tr v-for="i in pageSize" :key="i">
            <td
              v-for="field in fields"
              :key="field.key"
              class="!gl-border-l-0 !gl-border-r-0 !gl-border-t-0 !gl-border-section gl-bg-subtle !gl-px-5 !gl-py-3"
            >
              <gl-skeleton-loader :width="60" :lines="1" :equal-width-lines="true" />
            </td>
          </tr>
        </template>
      </tbody>
    </table>
  </div>
</template>

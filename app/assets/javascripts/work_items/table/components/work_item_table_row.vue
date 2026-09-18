<script>
import { GlFormCheckbox } from '@gitlab/ui';
import { getIdFromGraphQLId } from '~/graphql_shared/utils';
import { COLUMN_TITLE } from '../constants';
import WorkItemTableCell from './work_item_table_cell.vue';
import WorkItemTitleCell from './work_item_title_cell.vue';

export default {
  name: 'WorkItemTableRow',
  components: {
    GlFormCheckbox,
    WorkItemTableCell,
    WorkItemTitleCell,
  },
  props: {
    item: {
      type: Object,
      required: true,
    },
    columns: {
      type: Array,
      required: true,
    },
    rootPageFullPath: {
      type: String,
      required: true,
    },
    activeItem: {
      type: Object,
      required: false,
      default: null,
    },
    detailPanelEnabled: {
      type: Boolean,
      required: false,
      default: false,
    },
    showCheckbox: {
      type: Boolean,
      required: false,
      default: false,
    },
    checked: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  emits: ['set-active-item', 'checked-input'],
  computed: {
    isActive() {
      return Boolean(
        this.activeItem &&
        getIdFromGraphQLId(this.item.id) === getIdFromGraphQLId(this.activeItem.id),
      );
    },
    isRowClickable() {
      return this.detailPanelEnabled && !this.showCheckbox;
    },
    // Decides element and role once per column, so the template doesn't re-derive them
    // per cell. The title names the row, so it is the row's header cell, not a data cell.
    normalizedColumns() {
      return this.columns.map((column) => {
        const isTitle = column.key === COLUMN_TITLE;
        return { ...column, tag: isTitle ? 'th' : 'td', scope: isTitle ? 'row' : null, isTitle };
      });
    },
  },
  methods: {
    handleRowClick(event) {
      if (!this.isRowClickable) {
        return;
      }

      if (event.metaKey || event.ctrlKey || event.shiftKey) {
        return;
      }
      // Every other link in a row, an assignee or a milestone, points somewhere else and is
      // that link's own business. The title link is the one pointing at this work item.
      const link = event.target.closest('a');
      if (link && link.getAttribute('href') !== this.item.webPath) {
        return;
      }
      event.preventDefault();
      this.$emit('set-active-item', this.isActive ? null : this.item);
    },
  },
};
</script>

<template>
  <tr
    class="gl-border-b last:gl-border-b-0 hover:gl-bg-subtle"
    :class="{
      '!gl-bg-feedback-info hover:!gl-bg-feedback-info': isActive,
      'gl-cursor-pointer': isRowClickable,
    }"
    :aria-current="isActive ? 'true' : undefined"
    data-testid="work-item-table-row"
    @click="handleRowClick"
  >
    <td
      v-if="showCheckbox"
      class="gl-border-r gl-px-4 gl-py-3 gl-align-middle"
      data-testid="work-item-table-checkbox-cell"
    >
      <gl-form-checkbox
        class="gl-mx-auto gl-min-h-0 gl-w-5 gl-leading-16"
        :checked="checked"
        @input="$emit('checked-input', $event)"
      >
        <span class="gl-sr-only">{{ item.title }}</span>
      </gl-form-checkbox>
    </td>
    <component
      :is="column.tag"
      v-for="column in normalizedColumns"
      :key="column.key"
      :scope="column.scope"
      class="gl-border-r gl-truncate gl-px-4 gl-py-3 gl-text-left gl-align-middle gl-font-normal last:gl-border-r-0"
    >
      <work-item-title-cell v-if="column.isTitle" :item="item" />
      <work-item-table-cell
        v-else
        :item="item"
        :column-key="column.key"
        :root-page-full-path="rootPageFullPath"
      />
    </component>
  </tr>
</template>

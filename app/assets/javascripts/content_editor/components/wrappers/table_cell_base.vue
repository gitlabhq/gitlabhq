<script>
import { GlDisclosureDropdown } from '@gitlab/ui';
import { NodeViewWrapper, NodeViewContent } from '@tiptap/vue-2';
import { selectedRect as getSelectedRect } from '@tiptap/pm/tables';
import { __, n__ } from '~/locale';

const TABLE_CELL_HEADER = 'th';
const TABLE_CELL_BODY = 'td';

function getDropdownItems({ selectedRect, cellType, rowspan = 1, colspan = 1, align = 'left' }) {
  const totalRows = selectedRect?.map.height;
  const totalCols = selectedRect?.map.width;
  const isTableBodyCell = cellType === TABLE_CELL_BODY;
  const selectedRows = selectedRect ? selectedRect.bottom - selectedRect.top : 0;
  const selectedCols = selectedRect ? selectedRect.right - selectedRect.left : 0;
  const showSplitCellOption =
    selectedRows === rowspan && selectedCols === colspan && (rowspan > 1 || colspan > 1);
  const showMergeCellsOption = selectedRows !== rowspan || selectedCols !== colspan;
  const numCellsToMerge = (selectedRows - rowspan + 1) * (selectedCols - colspan + 1);
  const showDeleteRowOption = totalRows > selectedRows + 1 && isTableBodyCell;
  const showDeleteColumnOption = totalCols > selectedCols;

  const isTableBodyHeader = cellType === TABLE_CELL_HEADER;
  const showAlignLeftOption = isTableBodyHeader && (align === 'center' || align === 'right');
  const showAlignCenterOption = isTableBodyHeader && align !== 'center';
  const showAlignRightOption = isTableBodyHeader && align !== 'right';

  return [
    {
      items: [
        showAlignLeftOption && { text: __('Align column left'), value: 'alignColumnLeft' },
        showAlignCenterOption && { text: __('Align column center'), value: 'alignColumnCenter' },
        showAlignRightOption && { text: __('Align column right'), value: 'alignColumnRight' },
      ].filter(Boolean),
    },
    {
      items: [
        { text: __('Insert column left'), value: 'addColumnBefore' },
        { text: __('Insert column right'), value: 'addColumnAfter' },
        isTableBodyCell && { text: __('Insert row above'), value: 'addRowBefore' },
        { text: __('Insert row below'), value: 'addRowAfter' },
      ].filter(Boolean),
    },
    {
      items: [
        showSplitCellOption && { text: __('Split cell'), value: 'splitCell' },
        showMergeCellsOption && {
          text: n__('Merge %d cell', 'Merge %d cells', numCellsToMerge),
          value: 'mergeCells',
        },
      ].filter(Boolean),
    },
    {
      items: [
        showDeleteRowOption && {
          text: n__('Delete row', 'Delete %d rows', selectedRows),
          value: 'deleteRow',
        },
        showDeleteColumnOption && {
          text: n__('Delete column', 'Delete %d columns', selectedCols),
          value: 'deleteColumn',
        },
        { text: __('Delete table'), value: 'deleteTable' },
      ].filter(Boolean),
    },
  ].filter(({ items }) => items.length);
}

export default {
  name: 'TableCellBaseWrapper',
  components: {
    NodeViewWrapper,
    NodeViewContent,
    GlDisclosureDropdown,
  },
  props: {
    getPos: {
      type: Function,
      required: true,
    },
    cellType: {
      type: String,
      validator: (type) => [TABLE_CELL_HEADER, TABLE_CELL_BODY].includes(type),
      required: true,
    },
    editor: {
      type: Object,
      required: true,
    },
    node: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      displayActionsDropdown: false,
      selectedRect: null,
    };
  },
  computed: {
    dropdownItems() {
      return getDropdownItems({
        selectedRect: this.selectedRect,
        cellType: this.cellType,
        rowspan: this.node.attrs.rowspan,
        colspan: this.node.attrs.colspan,
        align: this.node.attrs.align,
      });
    },
  },
  mounted() {
    this.editor.on('selectionUpdate', this.handleSelectionUpdate);
    this.handleSelectionUpdate();
  },
  beforeDestroy() {
    this.editor.off('selectionUpdate', this.handleSelectionUpdate);
  },
  methods: {
    handleSelectionUpdate() {
      const { state } = this.editor;
      const { $cursor } = state.selection;

      try {
        this.selectedRect = getSelectedRect(state);
      } catch (e) {
        // ignore error if the selection is not in a table
        return;
      }

      if (!$cursor) return;

      this.displayActionsDropdown = false;

      for (let level = 0; level < $cursor.depth; level += 1) {
        if ($cursor.node(level) === this.node) {
          this.displayActionsDropdown = true;
          break;
        }
      }
    },

    runCommand({ value: command }) {
      this.hideDropdown();
      this.editor.chain()[command](this.getPos()).run();
    },

    hideDropdown() {
      this.$refs.dropdown?.close();
    },
  },
};
</script>
<template>
  <node-view-wrapper
    :as="cellType"
    :rowspan="node.attrs.rowspan || 1"
    :colspan="node.attrs.colspan || 1"
    :align="node.attrs.align || 'left'"
    dir="auto"
    class="gl-relative !gl-m-0 !gl-p-0"
    @click="hideDropdown"
  >
    <span
      v-if="displayActionsDropdown"
      :contenteditable="false"
      data-testid="actions-dropdown"
      class="gl-absolute gl-right-0 gl-top-0 gl-pr-1 gl-pt-1"
    >
      <gl-disclosure-dropdown
        ref="dropdown"
        dropup
        size="small"
        category="tertiary"
        boundary="viewport"
        text-sr-only
        :items="dropdownItems"
        :toggle-text="__('Edit table')"
        positioning-strategy="fixed"
        @action="runCommand"
      />
    </span>
    <node-view-content
      as="div"
      class="gl-min-w-10 gl-p-5"
      :style="{ 'text-align': node.attrs.align || 'left' }"
    />
  </node-view-wrapper>
</template>

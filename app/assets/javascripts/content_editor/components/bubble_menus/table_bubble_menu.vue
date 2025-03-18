<script>
import { GlDisclosureDropdown, GlTooltipDirective as GlTooltip } from '@gitlab/ui';
import { selectedRect as getSelectedRect, selectionCell, cellNear } from '@tiptap/pm/tables';
import { __, n__ } from '~/locale';
import EditorStateObserver from '../editor_state_observer.vue';
import Table from '../../extensions/table';
import TableHeader from '../../extensions/table_header';
import TableCell from '../../extensions/table_cell';
import { rectUnion } from '../../services/utils';
import BubbleMenu from './bubble_menu.vue';

function getDropdownItems({ selectedRect, cellType, rowspan = 1, colspan = 1, align = 'left' }) {
  const totalRows = selectedRect?.map.height;
  const totalCols = selectedRect?.map.width;
  const isTableBodyCell = cellType === TableCell.name;
  const selectedRows = selectedRect ? selectedRect.bottom - selectedRect.top : 0;
  const selectedCols = selectedRect ? selectedRect.right - selectedRect.left : 0;
  const showSplitCellOption =
    selectedRows === rowspan && selectedCols === colspan && (rowspan > 1 || colspan > 1);
  const showMergeCellsOption = selectedRows !== rowspan || selectedCols !== colspan;
  const numCellsToMerge = (selectedRows - rowspan + 1) * (selectedCols - colspan + 1);
  const showDeleteRowOption = totalRows > selectedRows + 1 && isTableBodyCell;
  const showDeleteColumnOption = totalCols > selectedCols;

  const isTableBodyHeader = cellType === TableHeader.name;
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
  components: {
    BubbleMenu,
    EditorStateObserver,
    GlDisclosureDropdown,
  },
  directives: {
    GlTooltip,
  },
  inject: ['tiptapEditor'],
  data() {
    return {
      dropdownItems: [],
    };
  },
  computed: {
    tippyOptions() {
      return {
        placement: 'top-end',
        offset: [-2, -26],
        getReferenceClientRect: this.getReferenceClientRect.bind(this),
      };
    },
  },
  methods: {
    shouldShow: ({ editor }) => {
      return editor.isActive(Table.name);
    },

    async updateTableInfo() {
      const { state } = this.tiptapEditor;

      try {
        this.selectedRect = getSelectedRect(state);
        const cell = cellNear(selectionCell(state)).nodeAfter;
        this.dropdownItems = getDropdownItems({
          selectedRect: this.selectedRect,
          cellType: cell.type.name,
          rowspan: cell.attrs.rowspan,
          colspan: cell.attrs.colspan,
          align: cell.attrs.align,
        });
      } catch (e) {
        // ignore error if the selection is not in a table
      }
    },

    getReferenceClientRect() {
      const { view } = this.tiptapEditor;
      const { from } = this.tiptapEditor.state.selection;
      let selectedCells = [
        ...view.domAtPos(from).node.closest('table').querySelectorAll('.selectedCell'),
      ];

      if (!selectedCells.length) {
        selectedCells = [view.domAtPos(from).node.closest('td, th')];
      }

      return rectUnion(...selectedCells.map((cell) => cell.getBoundingClientRect()));
    },

    runCommand({ value: command }) {
      const { state } = this.tiptapEditor;
      this.tiptapEditor.chain()[command](selectionCell(state)).run();
    },
  },
};
</script>
<template>
  <bubble-menu plugin-key="bubbleMenuTable" :should-show="shouldShow" :tippy-options="tippyOptions">
    <editor-state-observer :debounce="0" @transaction="updateTableInfo" />
    <gl-disclosure-dropdown
      ref="dropdown"
      dropup
      size="small"
      category="tertiary"
      boundary="viewport"
      :aria-label="__('Select action')"
      :toggle-text="__('Select action')"
      text-sr-only
      :items="dropdownItems"
      @action="runCommand"
    />
  </bubble-menu>
</template>

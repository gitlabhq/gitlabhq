<script>
import { GlDropdown, GlDropdownItem, GlDropdownDivider } from '@gitlab/ui';
import { NodeViewWrapper, NodeViewContent } from '@tiptap/vue-2';
import { selectedRect as getSelectedRect } from '@tiptap/pm/tables';
import { __ } from '~/locale';

const TABLE_CELL_HEADER = 'th';
const TABLE_CELL_BODY = 'td';

export default {
  name: 'TableCellBaseWrapper',
  components: {
    NodeViewWrapper,
    NodeViewContent,
    GlDropdown,
    GlDropdownItem,
    GlDropdownDivider,
  },
  props: {
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
      preventHide: true,
      selectedRect: null,
    };
  },
  computed: {
    totalRows() {
      return this.selectedRect?.map.height;
    },
    totalCols() {
      return this.selectedRect?.map.width;
    },
    isTableBodyCell() {
      return this.cellType === TABLE_CELL_BODY;
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

      if (!$cursor) return;

      this.displayActionsDropdown = false;

      for (let level = 0; level < $cursor.depth; level += 1) {
        if ($cursor.node(level) === this.node) {
          this.displayActionsDropdown = true;
          break;
        }
      }

      if (this.displayActionsDropdown) {
        this.selectedRect = getSelectedRect(state);
      }
    },
    runCommand(command) {
      this.editor.chain()[command]().run();
      this.hideDropdown();
    },
    handleHide($event) {
      if (this.preventHide) {
        $event.preventDefault();
      }
      this.preventHide = true;
    },
    hideDropdown() {
      this.preventHide = false;
      this.$refs.dropdown?.hide();
    },
  },
  i18n: {
    insertColumnBefore: __('Insert column before'),
    insertColumnAfter: __('Insert column after'),
    insertRowBefore: __('Insert row before'),
    insertRowAfter: __('Insert row after'),
    deleteRow: __('Delete row'),
    deleteColumn: __('Delete column'),
    deleteTable: __('Delete table'),
    editTableActions: __('Edit table'),
  },
  dropdownPopperOpts: {
    positionFixed: true,
  },
};
</script>
<template>
  <node-view-wrapper
    class="gl-relative gl-padding-5 gl-min-w-10"
    :as="cellType"
    dir="auto"
    @click="hideDropdown"
  >
    <span
      v-if="displayActionsDropdown"
      contenteditable="false"
      class="gl-absolute gl-right-0 gl-top-0"
    >
      <gl-dropdown
        ref="dropdown"
        dropup
        icon="chevron-down"
        size="small"
        category="tertiary"
        boundary="viewport"
        no-caret
        text-sr-only
        :text="$options.i18n.editTableActions"
        :popper-opts="$options.dropdownPopperOpts"
        @hide="handleHide($event)"
      >
        <gl-dropdown-item @click="runCommand('addColumnBefore')">
          {{ $options.i18n.insertColumnBefore }}
        </gl-dropdown-item>
        <gl-dropdown-item @click="runCommand('addColumnAfter')">
          {{ $options.i18n.insertColumnAfter }}
        </gl-dropdown-item>
        <gl-dropdown-item v-if="isTableBodyCell" @click="runCommand('addRowBefore')">
          {{ $options.i18n.insertRowBefore }}
        </gl-dropdown-item>
        <gl-dropdown-item @click="runCommand('addRowAfter')">
          {{ $options.i18n.insertRowAfter }}
        </gl-dropdown-item>
        <gl-dropdown-divider />
        <gl-dropdown-item v-if="totalRows > 2 && isTableBodyCell" @click="runCommand('deleteRow')">
          {{ $options.i18n.deleteRow }}
        </gl-dropdown-item>
        <gl-dropdown-item v-if="totalCols > 1" @click="runCommand('deleteColumn')">
          {{ $options.i18n.deleteColumn }}
        </gl-dropdown-item>
        <gl-dropdown-item @click="runCommand('deleteTable')">
          {{ $options.i18n.deleteTable }}
        </gl-dropdown-item>
      </gl-dropdown>
    </span>
    <node-view-content />
  </node-view-wrapper>
</template>

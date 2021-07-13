import { GlDropdown, GlButton } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import ToolbarTableButton from '~/content_editor/components/toolbar_table_button.vue';
import { tiptapExtension as Table } from '~/content_editor/extensions/table';
import { tiptapExtension as TableCell } from '~/content_editor/extensions/table_cell';
import { tiptapExtension as TableHeader } from '~/content_editor/extensions/table_header';
import { tiptapExtension as TableRow } from '~/content_editor/extensions/table_row';
import { createTestEditor, mockChainedCommands } from '../test_utils';

describe('content_editor/components/toolbar_table_button', () => {
  let wrapper;
  let editor;

  const buildWrapper = () => {
    wrapper = mountExtended(ToolbarTableButton, {
      propsData: {
        tiptapEditor: editor,
      },
    });
  };

  const findDropdown = () => wrapper.findComponent(GlDropdown);
  const getNumButtons = () => findDropdown().findAllComponents(GlButton).length;

  beforeEach(() => {
    editor = createTestEditor({
      extensions: [Table, TableCell, TableRow, TableHeader],
    });

    buildWrapper();
  });

  afterEach(() => {
    editor.destroy();
    wrapper.destroy();
  });

  it('renders a grid of 3x3 buttons to create a table', () => {
    expect(getNumButtons()).toBe(9); // 3 x 3
  });

  describe.each`
    row  | col  | numButtons | tableSize
    ${1} | ${2} | ${9}       | ${'1x2'}
    ${2} | ${2} | ${9}       | ${'2x2'}
    ${2} | ${3} | ${12}      | ${'2x3'}
    ${3} | ${2} | ${12}      | ${'3x2'}
    ${3} | ${3} | ${16}      | ${'3x3'}
  `('button($row, $col) in the table creator grid', ({ row, col, numButtons, tableSize }) => {
    describe('on mouse over', () => {
      beforeEach(async () => {
        const button = wrapper.findByTestId(`table-${row}-${col}`);
        await button.trigger('mouseover');
      });

      it('marks all rows and cols before it as active', () => {
        const prevRow = Math.max(1, row - 1);
        const prevCol = Math.max(1, col - 1);
        expect(wrapper.findByTestId(`table-${prevRow}-${prevCol}`).element).toHaveClass(
          'gl-bg-blue-50!',
        );
      });

      it('shows a help text indicating the size of the table being inserted', () => {
        expect(findDropdown().element).toHaveText(`Insert a ${tableSize} table.`);
      });

      it('adds another row and col of buttons to create a bigger table', () => {
        expect(getNumButtons()).toBe(numButtons);
      });
    });

    describe('on click', () => {
      let commands;

      beforeEach(async () => {
        commands = mockChainedCommands(editor, ['focus', 'insertTable', 'run']);

        const button = wrapper.findByTestId(`table-${row}-${col}`);
        await button.trigger('mouseover');
        await button.trigger('click');
      });

      it('inserts a table with $tableSize rows and cols', () => {
        expect(commands.focus).toHaveBeenCalled();
        expect(commands.insertTable).toHaveBeenCalledWith({
          rows: row,
          cols: col,
          withHeaderRow: true,
        });
        expect(commands.run).toHaveBeenCalled();

        expect(wrapper.emitted().execute).toHaveLength(1);
      });
    });
  });

  it('does not create more buttons than a 8x8 grid', async () => {
    for (let i = 3; i < 8; i += 1) {
      expect(getNumButtons()).toBe(i * i);

      // eslint-disable-next-line no-await-in-loop
      await wrapper.findByTestId(`table-${i}-${i}`).trigger('mouseover');
      expect(findDropdown().element).toHaveText(`Insert a ${i}x${i} table.`);
    }

    expect(getNumButtons()).toBe(64); // 8x8 (and not 9x9)
  });
});

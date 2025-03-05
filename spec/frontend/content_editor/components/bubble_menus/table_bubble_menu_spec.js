import { nextTick } from 'vue';
import { GlDisclosureDropdown } from '@gitlab/ui';
import { CellSelection } from '@tiptap/pm/tables';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import BubbleMenu from '~/content_editor/components/bubble_menus/bubble_menu.vue';
import TableBubbleMenu from '~/content_editor/components/bubble_menus/table_bubble_menu.vue';
import { stubComponent } from 'helpers/stub_component';
import eventHubFactory from '~/helpers/event_hub_factory';
import Table from '~/content_editor/extensions/table';
import TableRow from '~/content_editor/extensions/table_row';
import TableHeader from '~/content_editor/extensions/table_header';
import TableCell from '~/content_editor/extensions/table_cell';
import { useFakeRequestAnimationFrame } from 'helpers/fake_request_animation_frame';
import {
  createTestEditor,
  emitEditorEvent,
  createTransactionWithMeta,
  mockChainedCommands,
} from '../../test_utils';

describe('content_editor/components/bubble_menus/table_bubble_menu', () => {
  let wrapper;
  let tiptapEditor;
  let eventHub;
  let commands;

  function selectCellContaining(text) {
    const { doc } = tiptapEditor.state;
    let cellPos = 0;

    // Find position of a cell for cursor placement
    doc.descendants((node, pos) => {
      if (node.type.name === 'paragraph' && node.maybeChild(0)?.text === text) {
        cellPos = pos + 1;
        return false;
      }
      return true;
    });

    if (cellPos) {
      tiptapEditor.commands.setTextSelection(cellPos);
    }

    return cellPos;
  }

  function selectColumnContaining(text) {
    const pos = selectCellContaining(text);
    const resolved = tiptapEditor.state.doc.resolve(pos - 2);
    const { tr } = tiptapEditor.state;

    tiptapEditor.view.dispatch(tr.setSelection(CellSelection.colSelection(resolved)));
  }

  useFakeRequestAnimationFrame();

  const buildEditor = () => {
    tiptapEditor = createTestEditor({
      extensions: [Table, TableRow, TableHeader, TableCell],
    });
    eventHub = eventHubFactory();
  };

  const buildWrapper = () => {
    wrapper = mountExtended(TableBubbleMenu, {
      provide: {
        tiptapEditor,
        eventHub,
      },
      stubs: {
        BubbleMenu: stubComponent(BubbleMenu),
      },
    });
  };

  const findBubbleMenu = () => wrapper.findComponent(BubbleMenu);
  const findDropdown = () => wrapper.findComponent(GlDisclosureDropdown);

  const showBubbleMenu = async () => {
    findBubbleMenu().vm.$emit('show');
    await emitEditorEvent({
      event: 'transaction',
      tiptapEditor,
      params: { transaction: createTransactionWithMeta() },
    });
    await nextTick();
  };

  const insertTable = async (html) => {
    tiptapEditor.commands.setContent(html);
    await nextTick();
  };

  beforeEach(() => {
    buildEditor();
    buildWrapper();
  });

  it('renders bubble menu component', async () => {
    await insertTable(`
      <table>
        <tbody>
          <tr><td>Cell 1</td><td>Cell 2</td></tr>
          <tr><td>Cell 3</td><td>Cell 4</td></tr>
        </tbody>
      </table>
    `);
    await showBubbleMenu();
    expect(findBubbleMenu().exists()).toBe(true);
    expect(findDropdown().exists()).toBe(true);
  });

  describe('bubble menu visibility', () => {
    it('is visible when Table is active', () => {
      jest.spyOn(tiptapEditor, 'isActive').mockReturnValue(true);

      expect(wrapper.vm.shouldShow({ editor: tiptapEditor })).toBe(true);
    });

    it('is not visible when Table is not active', () => {
      jest.spyOn(tiptapEditor, 'isActive').mockReturnValue(false);

      expect(wrapper.vm.shouldShow({ editor: tiptapEditor })).toBe(false);
    });
  });

  describe('dropdown display', () => {
    beforeEach(async () => {
      await insertTable(`
        <table>
          <tr>
            <th>Header 1</th>
            <th align="center">Header 2</th>
            <th align="right">Header 3</th>
          </tr>
          <tr>
            <td>Row 1 Cell 1</td>
            <td>Row 1 Cell 2</td>
            <td>Row 1 Cell 3</td>
          </tr>
          <tr>
            <td>Row 2 Cell 1</td>
            <td>Row 2 Cell 2</td>
            <td>Row 2 Cell 3</td>
          </tr>
        </table>
      `);
    });

    describe('common actions', () => {
      describe.each`
        label                    | action
        ${'Insert column left'}  | ${'addColumnBefore'}
        ${'Insert column right'} | ${'addColumnAfter'}
        ${'Insert row below'}    | ${'addRowAfter'}
        ${'Delete table'}        | ${'deleteTable'}
      `('action: $label', ({ label, action }) => {
        const cells = [
          'Header 1',
          'Header 2',
          'Header 3',
          'Row 1 Cell 1',
          'Row 1 Cell 2',
          'Row 1 Cell 3',
          'Row 2 Cell 1',
          'Row 2 Cell 2',
          'Row 2 Cell 3',
        ];

        it('is visible for all cells', async () => {
          for (const text of cells) {
            selectCellContaining(text);
            // eslint-disable-next-line no-await-in-loop
            await showBubbleMenu();
            expect(wrapper.text()).toContain(label);
          }
        });

        it(`executes a command to run action ${action}`, async () => {
          commands = mockChainedCommands(tiptapEditor, [action, 'run']);

          for (const text of cells) {
            selectCellContaining(text);
            // eslint-disable-next-line no-await-in-loop
            await showBubbleMenu();
            // eslint-disable-next-line no-await-in-loop
            await wrapper.findByRole('button', { name: label }).trigger('click');

            expect(commands[action]).toHaveBeenCalled();
          }
        });
      });
    });

    describe('action: Insert row above', () => {
      it('is not visible on a th', async () => {
        selectCellContaining('Header 1');
        await showBubbleMenu();
        expect(wrapper.text()).not.toContain('Insert row above');
      });

      it('is visible on a td', async () => {
        selectCellContaining('Row 1 Cell 1');
        await showBubbleMenu();
        expect(wrapper.text()).toContain('Insert row above');
      });

      it('executes a command to insert row above', async () => {
        commands = mockChainedCommands(tiptapEditor, ['addRowBefore', 'run']);

        selectCellContaining('Row 1 Cell 1');
        await showBubbleMenu();
        await wrapper.findByRole('button', { name: 'Insert row above' }).trigger('click');

        expect(commands.addRowBefore).toHaveBeenCalled();
      });
    });

    describe('action: Align column left', () => {
      it('is not visible on a td', async () => {
        selectCellContaining('Row 1 Cell 1');
        await showBubbleMenu();
        expect(wrapper.text()).not.toContain('Align column left');
      });

      it('is not visible if a th is aligned left', async () => {
        selectCellContaining('Header 1');
        await showBubbleMenu();
        expect(wrapper.text()).not.toContain('Align column left');
      });

      it('is visible when a th is not aligned left', async () => {
        selectCellContaining('Header 2');
        await showBubbleMenu();
        expect(wrapper.text()).toContain('Align column left');

        selectCellContaining('Header 3');
        await showBubbleMenu();
        expect(wrapper.text()).toContain('Align column left');
      });

      it('executes a command to align column left', async () => {
        commands = mockChainedCommands(tiptapEditor, ['alignColumnLeft', 'run']);

        selectCellContaining('Header 2');
        await showBubbleMenu();
        await wrapper.findByRole('button', { name: 'Align column left' }).trigger('click');

        expect(commands.alignColumnLeft).toHaveBeenCalled();
      });
    });

    describe('action: Align column center', () => {
      it('is not visible on a td', async () => {
        selectCellContaining('Row 1 Cell 1');
        await showBubbleMenu();
        expect(wrapper.text()).not.toContain('Align column center');
      });

      it('is not visible if a th is aligned center', async () => {
        selectCellContaining('Header 2');
        await showBubbleMenu();
        expect(wrapper.text()).not.toContain('Align column center');
      });

      it('is visible when a th is not aligned center', async () => {
        selectCellContaining('Header 1');
        await showBubbleMenu();
        expect(wrapper.text()).toContain('Align column center');

        selectCellContaining('Header 3');
        await showBubbleMenu();
        expect(wrapper.text()).toContain('Align column center');
      });

      it('executes a command to align column center', async () => {
        commands = mockChainedCommands(tiptapEditor, ['alignColumnCenter', 'run']);

        selectCellContaining('Header 1');
        await showBubbleMenu();
        await wrapper.findByRole('button', { name: 'Align column center' }).trigger('click');

        expect(commands.alignColumnCenter).toHaveBeenCalled();
      });
    });

    describe('action: Align column right', () => {
      it('is not visible on a td', async () => {
        selectCellContaining('Row 1 Cell 1');
        await showBubbleMenu();
        expect(wrapper.text()).not.toContain('Align column right');
      });

      it('is not visible if a th is aligned right', async () => {
        selectCellContaining('Header 3');
        await showBubbleMenu();
        expect(wrapper.text()).not.toContain('Align column right');
      });

      it('is visible when a th is not aligned right', async () => {
        selectCellContaining('Header 1');
        await showBubbleMenu();
        expect(wrapper.text()).toContain('Align column right');

        selectCellContaining('Header 2');
        await showBubbleMenu();
        expect(wrapper.text()).toContain('Align column right');
      });

      it('executes a command to align column right', async () => {
        commands = mockChainedCommands(tiptapEditor, ['alignColumnRight', 'run']);

        selectCellContaining('Header 1');
        await showBubbleMenu();
        await wrapper.findByRole('button', { name: 'Align column right' }).trigger('click');

        expect(commands.alignColumnRight).toHaveBeenCalled();
      });
    });

    describe('action: Delete row', () => {
      it('is not visible on a th', async () => {
        selectCellContaining('Header 1');
        await showBubbleMenu();
        expect(wrapper.text()).not.toContain('Delete row');
      });

      it('is visible on a td', async () => {
        selectCellContaining('Row 1 Cell 1');
        await showBubbleMenu();
        expect(wrapper.text()).toContain('Delete row');
      });

      it('is not visible when there is only one row', async () => {
        await insertTable(`
          <table>
            <tbody>
              <tr><td>Single Row Cell 1</td><td>Single Row Cell 2</td></tr>
            </tbody>
          </table>
        `);

        selectCellContaining('Single Row Cell 1');
        await showBubbleMenu();
        expect(wrapper.text()).not.toContain('Delete row');

        selectCellContaining('Single Row Cell 2');
        await showBubbleMenu();
        expect(wrapper.text()).not.toContain('Delete row');
      });

      it('executes a command to delete row', async () => {
        commands = mockChainedCommands(tiptapEditor, ['deleteRow', 'run']);

        selectCellContaining('Row 1 Cell 1');
        await showBubbleMenu();
        await wrapper.findByRole('button', { name: 'Delete row' }).trigger('click');

        expect(commands.deleteRow).toHaveBeenCalled();
      });
    });

    describe('action: Delete column', () => {
      it('is visible on a td and th', async () => {
        selectCellContaining('Header 1');
        await showBubbleMenu();
        expect(wrapper.text()).toContain('Delete column');

        selectCellContaining('Row 1 Cell 1');
        await showBubbleMenu();
        expect(wrapper.text()).toContain('Delete column');
      });

      it('is not visible when there is only one column', async () => {
        await insertTable(`
          <table>
            <tbody>
              <tr><td>Single Column Cell 1</td></tr>
              <tr><td>Single Column Cell 2</td></tr>
            </tbody>
          </table>
        `);

        selectCellContaining('Single Column Cell 1');
        await showBubbleMenu();
        expect(wrapper.text()).not.toContain('Delete column');

        selectCellContaining('Single Column Cell 2');
        await showBubbleMenu();
        expect(wrapper.text()).not.toContain('Delete column');
      });

      it('executes a command to delete column', async () => {
        commands = mockChainedCommands(tiptapEditor, ['deleteColumn', 'run']);

        selectCellContaining('Row 1 Cell 1');
        await showBubbleMenu();
        await wrapper.findByRole('button', { name: 'Delete column' }).trigger('click');

        expect(commands.deleteColumn).toHaveBeenCalled();
      });
    });

    describe('action: Split cell', () => {
      it('is not visible on a td with rowspan 1 and colspan 1', async () => {
        selectCellContaining('Row 1 Cell 1');
        await showBubbleMenu();
        expect(wrapper.text()).not.toContain('Split cell');
      });

      it('is visible on a td with rowspan > 1', async () => {
        await insertTable(`
          <table>
            <tbody>
              <tr><td rowspan="2">Spanned Cell</td><td>Cell 2</td></tr>
              <tr><td>Cell 3</td></tr>
            </tbody>
          </table>
        `);

        selectCellContaining('Spanned Cell');
        await showBubbleMenu();
        expect(wrapper.text()).toContain('Split cell');
      });

      it('is visible on a td with colspan > 1', async () => {
        await insertTable(`
          <table>
            <tbody>
              <tr><td colspan="2">Spanned Cell</td></tr>
              <tr><td>Cell 2</td><td>Cell 3</td></tr>
            </tbody>
          </table>
        `);

        selectCellContaining('Spanned Cell');
        await showBubbleMenu();
        expect(wrapper.text()).toContain('Split cell');
      });
    });

    describe('action: Merge cells', () => {
      it('is not visible on a single cell selection', async () => {
        selectCellContaining('Row 1 Cell 1');
        await showBubbleMenu();
        expect(wrapper.text()).not.toContain('Merge cells');
      });

      it('is visible when multiple cells are selected', async () => {
        await insertTable(`
          <table>
            <tbody>
              <tr><td>Cell 1</td><td>Cell 2</td></tr>
              <tr><td>Cell 3</td><td>Cell 4</td></tr>
            </tbody>
          </table>
        `);

        selectColumnContaining('Cell 3');
        await showBubbleMenu();
        expect(wrapper.text()).toContain('Merge 2 cells');
      });

      it('executes a command to merge cells', async () => {
        await insertTable(`
          <table>
            <tbody>
              <tr><td>Cell 1</td><td>Cell 2</td></tr>
              <tr><td>Cell 3</td><td>Cell 4</td></tr>
            </tbody>
          </table>
        `);

        commands = mockChainedCommands(tiptapEditor, ['mergeCells', 'run']);

        selectColumnContaining('Cell 3');
        await showBubbleMenu();
        await wrapper.findByRole('button', { name: 'Merge 2 cells' }).trigger('click');

        expect(commands.mergeCells).toHaveBeenCalled();
      });
    });
  });
});

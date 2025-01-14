import { GlDisclosureDropdown } from '@gitlab/ui';
import { NodeViewWrapper, NodeViewContent } from '@tiptap/vue-2';
import { selectedRect as getSelectedRect } from '@tiptap/pm/tables';
import { nextTick } from 'vue';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import { stubComponent } from 'helpers/stub_component';
import { useFakeRequestAnimationFrame } from 'helpers/fake_request_animation_frame';
import TableCellBaseWrapper from '~/content_editor/components/wrappers/table_cell_base.vue';
import { createTestEditor, mockChainedCommands, emitEditorEvent } from '../../test_utils';

jest.mock('@tiptap/pm/tables');

describe('content/components/wrappers/table_cell_base', () => {
  let wrapper;
  let editor;
  let node;

  // Stubbing requestAnimationFrame because GlDisclosureDropdown uses it to delay its `action` event.
  useFakeRequestAnimationFrame();

  const createWrapper = (propsData = { cellType: 'td' }) => {
    wrapper = mountExtended(TableCellBaseWrapper, {
      propsData: {
        editor,
        node,
        getPos: () => 0,
        ...propsData,
      },
      stubs: {
        NodeViewWrapper: stubComponent(NodeViewWrapper),
        NodeViewContent: stubComponent(NodeViewContent),
      },
    });
  };

  const findDropdown = () => wrapper.findComponent(GlDisclosureDropdown);
  const setCurrentPositionInCell = () => {
    const { $cursor } = editor.state.selection;

    jest.spyOn($cursor, 'node').mockReturnValue(node);
  };

  beforeEach(() => {
    node = {
      attrs: {},
    };
    editor = createTestEditor({});
  });

  it('renders a td node-view-wrapper with relative position', () => {
    createWrapper();
    expect(wrapper.findComponent(NodeViewWrapper).classes()).toContain('gl-relative');
    expect(wrapper.findComponent(NodeViewWrapper).props().as).toBe('td');
  });

  it('displays dropdown when selection cursor is on the cell', async () => {
    setCurrentPositionInCell();
    createWrapper();

    await nextTick();

    expect(findDropdown().props()).toMatchObject({
      category: 'tertiary',
      size: 'small',
    });
    expect(findDropdown().attributes()).toMatchObject({
      boundary: 'viewport',
    });
  });

  it('does not display dropdown when selection cursor is not on the cell', async () => {
    createWrapper();

    await nextTick();

    expect(findDropdown().exists()).toBe(false);
  });

  describe('when dropdown is visible', () => {
    beforeEach(async () => {
      setCurrentPositionInCell();
      getSelectedRect.mockReturnValue({
        top: 0,
        left: 0,
        bottom: 1,
        right: 1,
        map: {
          height: 1,
          width: 1,
        },
      });

      createWrapper();
      await nextTick();
    });

    it.each`
      dropdownItemLabel        | commandName
      ${'Insert column left'}  | ${'addColumnBefore'}
      ${'Insert column right'} | ${'addColumnAfter'}
      ${'Insert row above'}    | ${'addRowBefore'}
      ${'Insert row below'}    | ${'addRowAfter'}
      ${'Delete table'}        | ${'deleteTable'}
    `(
      'executes $commandName when $dropdownItemLabel button is clicked',
      async ({ dropdownItemLabel, commandName }) => {
        const mocks = mockChainedCommands(editor, [commandName, 'run']);

        await wrapper.findByRole('button', { name: dropdownItemLabel }).trigger('click');

        expect(mocks[commandName]).toHaveBeenCalled();
      },
    );

    it.each`
      dropdownItemLabel
      ${'Delete row'}
      ${'Delete column'}
      ${'Split cell'}
      ${'Merge'}
    `('does not have option $dropdownItemLabel available', ({ dropdownItemLabel }) => {
      expect(findDropdown().text()).not.toContain(dropdownItemLabel);
    });

    it.each`
      dropdownItemLabel  | commandName
      ${'Delete row'}    | ${'deleteRow'}
      ${'Delete column'} | ${'deleteColumn'}
    `(
      'allows $dropdownItemLabel operation when there are more than 2 rows and 1 column in the table',
      async ({ dropdownItemLabel, commandName }) => {
        const mocks = mockChainedCommands(editor, [commandName, 'run']);

        getSelectedRect.mockReturnValue({
          top: 0,
          left: 0,
          bottom: 1,
          right: 1,
          map: {
            height: 3,
            width: 2,
          },
        });

        emitEditorEvent({ tiptapEditor: editor, event: 'selectionUpdate' });

        await nextTick();
        await wrapper.findByRole('button', { name: dropdownItemLabel }).trigger('click');

        expect(mocks[commandName]).toHaveBeenCalled();
      },
    );

    it('does not show alignment options for table cells', () => {
      expect(findDropdown().text()).not.toContain('Align');
    });

    describe("when current row is the table's header", () => {
      beforeEach(async () => {
        // Remove 2 rows condition
        getSelectedRect.mockReturnValue({
          map: {
            height: 3,
          },
        });

        createWrapper({ cellType: 'th' });

        await nextTick();
      });

      it('does not allow adding a row before the header', () => {
        expect(findDropdown().text()).not.toContain('Insert row before');
        expect(wrapper.findByTestId('actions-dropdown').attributes('contenteditable')).toBe(
          'false',
        );
      });

      it('does not allow removing the header row', async () => {
        createWrapper({ cellType: 'th' });

        await nextTick();

        expect(findDropdown().text()).not.toContain('Delete row');
      });
    });

    describe.each`
      currentAlignment | visibleOptions         | newAlignment | command
      ${'left'}        | ${['center', 'right']} | ${'center'}  | ${'alignColumnCenter'}
      ${'center'}      | ${['left', 'right']}   | ${'right'}   | ${'alignColumnRight'}
      ${'right'}       | ${['left', 'center']}  | ${'left'}    | ${'alignColumnLeft'}
    `(
      'when align=$currentAlignment',
      ({ currentAlignment, visibleOptions, newAlignment, command }) => {
        beforeEach(async () => {
          Object.assign(node.attrs, { align: currentAlignment });

          createWrapper({ cellType: 'th' });

          await nextTick();
        });

        visibleOptions.forEach((alignment) => {
          it(`shows "Align column ${alignment}" option`, () => {
            expect(findDropdown().text()).toContain(`Align column ${alignment}`);
          });
        });

        it(`does not show "Align column ${currentAlignment}" option`, () => {
          expect(findDropdown().text()).not.toContain(`Align column ${currentAlignment}`);
        });

        it('allows changing alignment', async () => {
          const mocks = mockChainedCommands(editor, [command, 'run']);

          await wrapper
            .findByRole('button', { name: `Align column ${newAlignment}` })
            .trigger('click');

          expect(mocks[command]).toHaveBeenCalled();
        });
      },
    );

    describe.each`
      attrs             | rect
      ${{ rowspan: 2 }} | ${{ top: 0, left: 0, bottom: 2, right: 1 }}
      ${{ colspan: 2 }} | ${{ top: 0, left: 0, bottom: 1, right: 2 }}
    `('when selected cell has $attrs', ({ attrs, rect }) => {
      beforeEach(() => {
        node = { attrs };

        getSelectedRect.mockReturnValue({
          ...rect,
          map: {
            height: 3,
            width: 2,
          },
        });

        setCurrentPositionInCell();
      });

      it('allows splitting the cell', async () => {
        const mocks = mockChainedCommands(editor, ['splitCell', 'run']);

        createWrapper();

        await nextTick();
        await wrapper.findByRole('button', { name: 'Split cell' }).trigger('click');

        expect(mocks.splitCell).toHaveBeenCalled();
      });
    });

    describe('when selected cell has rowspan=2 and colspan=2', () => {
      beforeEach(() => {
        node = { attrs: { rowspan: 2, colspan: 2 } };
        const rect = { top: 1, left: 1, bottom: 3, right: 3 };

        getSelectedRect.mockReturnValue({
          ...rect,
          map: { height: 5, width: 5 },
        });

        setCurrentPositionInCell();
      });

      it.each`
        type         | dropdownItemLabel     | commandName
        ${'rows'}    | ${'Delete 2 rows'}    | ${'deleteRow'}
        ${'columns'} | ${'Delete 2 columns'} | ${'deleteColumn'}
      `('shows correct label for deleting $type', async ({ dropdownItemLabel, commandName }) => {
        const mocks = mockChainedCommands(editor, [commandName, 'run']);

        createWrapper();

        await nextTick();
        await wrapper.findByRole('button', { name: dropdownItemLabel }).trigger('click');

        expect(mocks[commandName]).toHaveBeenCalled();
      });
    });

    describe.each`
      rows | cols | product
      ${2} | ${1} | ${2}
      ${1} | ${2} | ${2}
      ${2} | ${2} | ${4}
    `('when $rows x $cols ($product) cells are selected', ({ rows, cols, product }) => {
      it.each`
        dropdownItemLabel                                          | commandName
        ${`Merge ${product} cells`}                                | ${'mergeCells'}
        ${rows === 1 ? 'Delete row' : `Delete ${rows} rows`}       | ${'deleteRow'}
        ${cols === 1 ? 'Delete column' : `Delete ${cols} columns`} | ${'deleteColumn'}
      `(
        'executes $commandName when $dropdownItemLabel is clicked',
        async ({ dropdownItemLabel, commandName }) => {
          const mocks = mockChainedCommands(editor, [commandName, 'run']);

          getSelectedRect.mockReturnValue({
            top: 0,
            left: 0,
            bottom: rows,
            right: cols,
            map: {
              height: 4,
              width: 4,
            },
          });

          emitEditorEvent({ tiptapEditor: editor, event: 'selectionUpdate' });

          await nextTick();
          await wrapper.findByRole('button', { name: dropdownItemLabel }).trigger('click');

          expect(mocks[commandName]).toHaveBeenCalled();
        },
      );
    });
  });
});

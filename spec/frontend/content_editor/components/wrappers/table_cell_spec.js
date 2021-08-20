import { GlDropdown, GlDropdownItem } from '@gitlab/ui';
import { NodeViewWrapper } from '@tiptap/vue-2';
import { selectedRect as getSelectedRect } from 'prosemirror-tables';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import TableCellWrapper from '~/content_editor/components/wrappers/table_cell.vue';
import { createTestEditor, mockChainedCommands, emitEditorEvent } from '../../test_utils';

jest.mock('prosemirror-tables');

describe('content/components/wrappers/table_cell', () => {
  let wrapper;
  let editor;
  let getPos;

  const createWrapper = async () => {
    wrapper = shallowMountExtended(TableCellWrapper, {
      propsData: {
        editor,
        getPos,
      },
    });
  };

  const findDropdown = () => wrapper.findComponent(GlDropdown);
  const findDropdownItemWithLabel = (name) =>
    wrapper
      .findAllComponents(GlDropdownItem)
      .filter((dropdownItem) => dropdownItem.text().includes(name))
      .at(0);
  const findDropdownItemWithLabelExists = (name) =>
    wrapper
      .findAllComponents(GlDropdownItem)
      .filter((dropdownItem) => dropdownItem.text().includes(name)).length > 0;
  const setCurrentPositionInCell = () => {
    const { $cursor } = editor.state.selection;

    getPos.mockReturnValue($cursor.pos - $cursor.parentOffset - 1);
  };
  const mockDropdownHide = () => {
    /*
     * TODO: Replace this method with using the scoped hide function
     * provided by BootstrapVue https://bootstrap-vue.org/docs/components/dropdown.
     * GitLab UI is not exposing it in the default scope
     */
    findDropdown().vm.hide = jest.fn();
  };

  beforeEach(() => {
    getPos = jest.fn();
    editor = createTestEditor({});
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('renders a td node-view-wrapper with relative position', () => {
    createWrapper();
    expect(wrapper.findComponent(NodeViewWrapper).classes()).toContain('gl-relative');
    expect(wrapper.findComponent(NodeViewWrapper).props().as).toBe('td');
  });

  it('displays dropdown when selection cursor is on the cell', async () => {
    setCurrentPositionInCell();
    createWrapper();

    await wrapper.vm.$nextTick();

    expect(findDropdown().props()).toMatchObject({
      category: 'tertiary',
      icon: 'chevron-down',
      size: 'small',
      split: false,
    });
    expect(findDropdown().attributes()).toMatchObject({
      boundary: 'viewport',
      'no-caret': '',
    });
  });

  it('does not display dropdown when selection cursor is not on the cell', async () => {
    createWrapper();

    await wrapper.vm.$nextTick();

    expect(findDropdown().exists()).toBe(false);
  });

  describe('when dropdown is visible', () => {
    beforeEach(async () => {
      setCurrentPositionInCell();
      getSelectedRect.mockReturnValue({
        map: {
          height: 1,
          width: 1,
        },
      });

      createWrapper();
      await wrapper.vm.$nextTick();

      mockDropdownHide();
    });

    it.each`
      dropdownItemLabel         | commandName
      ${'Insert column before'} | ${'addColumnBefore'}
      ${'Insert column after'}  | ${'addColumnAfter'}
      ${'Insert row before'}    | ${'addRowBefore'}
      ${'Insert row after'}     | ${'addRowAfter'}
      ${'Delete table'}         | ${'deleteTable'}
    `(
      'executes $commandName when $dropdownItemLabel button is clicked',
      ({ commandName, dropdownItemLabel }) => {
        const mocks = mockChainedCommands(editor, [commandName, 'run']);

        findDropdownItemWithLabel(dropdownItemLabel).vm.$emit('click');

        expect(mocks[commandName]).toHaveBeenCalled();
      },
    );

    it('does not allow deleting rows and columns', async () => {
      expect(findDropdownItemWithLabelExists('Delete row')).toBe(false);
      expect(findDropdownItemWithLabelExists('Delete column')).toBe(false);
    });

    it('allows deleting rows when there are more than 2 rows in the table', async () => {
      const mocks = mockChainedCommands(editor, ['deleteRow', 'run']);

      getSelectedRect.mockReturnValue({
        map: {
          height: 3,
        },
      });

      emitEditorEvent({ tiptapEditor: editor, event: 'selectionUpdate' });

      await wrapper.vm.$nextTick();

      findDropdownItemWithLabel('Delete row').vm.$emit('click');

      expect(mocks.deleteRow).toHaveBeenCalled();
    });

    it('allows deleting columns when there are more than 1 column in the table', async () => {
      const mocks = mockChainedCommands(editor, ['deleteColumn', 'run']);

      getSelectedRect.mockReturnValue({
        map: {
          width: 2,
        },
      });

      emitEditorEvent({ tiptapEditor: editor, event: 'selectionUpdate' });

      await wrapper.vm.$nextTick();

      findDropdownItemWithLabel('Delete column').vm.$emit('click');

      expect(mocks.deleteColumn).toHaveBeenCalled();
    });
  });
});

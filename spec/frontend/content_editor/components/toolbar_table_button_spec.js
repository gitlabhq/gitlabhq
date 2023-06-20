import { GlDisclosureDropdown, GlButton } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import ToolbarTableButton from '~/content_editor/components/toolbar_table_button.vue';
import { stubComponent } from 'helpers/stub_component';
import { createTestEditor, mockChainedCommands } from '../test_utils';

describe('content_editor/components/toolbar_table_button', () => {
  let wrapper;
  let editor;

  const buildWrapper = () => {
    wrapper = mountExtended(ToolbarTableButton, {
      provide: {
        tiptapEditor: editor,
      },
      stubs: {
        GlDisclosureDropdown: stubComponent(GlDisclosureDropdown),
      },
    });
  };

  const findDropdown = () => wrapper.findComponent(GlDisclosureDropdown);
  const findButton = (row, col) => wrapper.findComponent({ ref: `table-${row}-${col}` });
  const getNumButtons = () => findDropdown().findAllComponents(GlButton).length;

  beforeEach(() => {
    editor = createTestEditor();

    buildWrapper();
  });

  afterEach(() => {
    editor.destroy();
  });

  describe.each`
    row  | col  | numButtons | tableSize
    ${3} | ${4} | ${25}      | ${'3×4'}
    ${4} | ${4} | ${25}      | ${'4×4'}
    ${4} | ${5} | ${30}      | ${'4×5'}
    ${5} | ${4} | ${30}      | ${'5×4'}
    ${5} | ${5} | ${36}      | ${'5×5'}
  `('button($row, $col) in the table creator grid', ({ row, col, numButtons, tableSize }) => {
    describe('a11y tests', () => {
      it('is in its own gridcell', () => {
        expect(findButton(row, col).element.parentElement.getAttribute('role')).toBe('gridcell');
      });

      it('has an aria-label', () => {
        expect(findButton(row, col).attributes('aria-label')).toBe(`Insert a ${tableSize} table`);
      });
    });

    describe.each`
      event          | triggerEvent
      ${'mouseover'} | ${(button) => button.trigger('mouseover')}
      ${'focus'}     | ${(button) => button.element.dispatchEvent(new FocusEvent('focus'))}
    `('on $event', ({ triggerEvent }) => {
      beforeEach(async () => {
        const button = wrapper.findComponent({ ref: `table-${row}-${col}` });
        await triggerEvent(button);
      });

      it('marks all rows and cols before it as active', () => {
        const prevRow = Math.max(1, row - 1);
        const prevCol = Math.max(1, col - 1);
        expect(wrapper.findComponent({ ref: `table-${prevRow}-${prevCol}` }).element).toHaveClass(
          'active',
        );
      });

      it('shows a help text indicating the size of the table being inserted', () => {
        expect(findDropdown().element).toHaveText(`Insert a ${tableSize} table`);
      });

      it('adds another row and col of buttons to create a bigger table', () => {
        expect(getNumButtons()).toBe(numButtons);
      });
    });

    describe('on click', () => {
      let commands;

      beforeEach(async () => {
        commands = mockChainedCommands(editor, ['focus', 'insertTable', 'run']);

        const button = wrapper.findComponent({ ref: `table-${row}-${col}` });
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

  it('does not create more buttons than a 10x10 grid', async () => {
    for (let i = 5; i < 10; i += 1) {
      expect(getNumButtons()).toBe(i * i);

      // eslint-disable-next-line no-await-in-loop
      await wrapper.findComponent({ ref: `table-${i}-${i}` }).trigger('mouseover');
      expect(findDropdown().element).toHaveText(`Insert a ${i}×${i} table`);
    }

    expect(getNumButtons()).toBe(100); // 10x10 (and not 11x11)
  });

  describe('a11y tests', () => {
    it('sets text, title, and text-sr-only properties to the table button dropdown', () => {
      expect(findDropdown().props()).toMatchObject({
        toggleText: 'Insert table',
        textSrOnly: true,
      });
      expect(findDropdown().attributes('aria-label')).toBe('Insert table');
    });

    it('renders a role=grid of 5x5 gridcells to create a table', () => {
      expect(getNumButtons()).toBe(25); // 5x5
      expect(wrapper.find('[role="grid"]').exists()).toBe(true);
      wrapper.findAll('[role="row"]').wrappers.forEach((row) => {
        expect(row.findAll('[role="gridcell"]')).toHaveLength(5);
      });
    });

    it('sets aria-rowcount and aria-colcount on the dropdown contents', () => {
      expect(wrapper.find('[role="grid"]').attributes()).toMatchObject({
        'aria-rowcount': '10',
        'aria-colcount': '10',
      });
    });

    it('allows navigating the grid with the arrow keys', async () => {
      const dispatchKeyboardEvent = (button, key) =>
        button.element.dispatchEvent(new KeyboardEvent('keydown', { key }));

      let button = findButton(3, 4);
      await button.trigger('mouseover');
      expect(button.element).toHaveClass('active');

      button = findButton(3, 5);
      await dispatchKeyboardEvent(button, 'ArrowRight');
      expect(button.element).toHaveClass('active');

      button = findButton(4, 5);
      await dispatchKeyboardEvent(button, 'ArrowDown');
      expect(button.element).toHaveClass('active');

      button = findButton(4, 4);
      await dispatchKeyboardEvent(button, 'ArrowLeft');
      expect(button.element).toHaveClass('active');

      button = findButton(3, 4);
      await dispatchKeyboardEvent(button, 'ArrowUp');
      expect(button.element).toHaveClass('active');
    });
  });
});

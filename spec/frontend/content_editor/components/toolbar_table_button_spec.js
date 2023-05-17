import { GlDropdown, GlButton } from '@gitlab/ui';
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
        GlDropdown: stubComponent(GlDropdown),
      },
    });
  };

  const findDropdown = () => wrapper.findComponent(GlDropdown);
  const getNumButtons = () => findDropdown().findAllComponents(GlButton).length;

  beforeEach(() => {
    editor = createTestEditor();

    buildWrapper();
  });

  afterEach(() => {
    editor.destroy();
  });

  it('renders a grid of 5x5 buttons to create a table', () => {
    expect(getNumButtons()).toBe(25); // 5x5
  });

  describe.each`
    row  | col  | numButtons | tableSize
    ${3} | ${4} | ${25}      | ${'3x4'}
    ${4} | ${4} | ${25}      | ${'4x4'}
    ${4} | ${5} | ${30}      | ${'4x5'}
    ${5} | ${4} | ${30}      | ${'5x4'}
    ${5} | ${5} | ${36}      | ${'5x5'}
  `('button($row, $col) in the table creator grid', ({ row, col, numButtons, tableSize }) => {
    describe('on mouse over', () => {
      beforeEach(async () => {
        const button = wrapper.findByTestId(`table-${row}-${col}`);
        await button.trigger('mouseover');
      });

      it('marks all rows and cols before it as active', () => {
        const prevRow = Math.max(1, row - 1);
        const prevCol = Math.max(1, col - 1);
        expect(wrapper.findByTestId(`table-${prevRow}-${prevCol}`).element).toHaveClass('active');
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

  it('does not create more buttons than a 10x10 grid', async () => {
    for (let i = 5; i < 10; i += 1) {
      expect(getNumButtons()).toBe(i * i);

      // eslint-disable-next-line no-await-in-loop
      await wrapper.findByTestId(`table-${i}-${i}`).trigger('mouseover');
      expect(findDropdown().element).toHaveText(`Insert a ${i}x${i} table.`);
    }

    expect(getNumButtons()).toBe(100); // 10x10 (and not 11x11)
  });

  describe('a11y tests', () => {
    it('sets text, title, and text-sr-only properties to the table button dropdown', () => {
      expect(findDropdown().props()).toMatchObject({
        text: 'Insert table',
        textSrOnly: true,
      });
      expect(findDropdown().attributes('title')).toBe('Insert table');
    });
  });
});

import { mountExtended } from 'helpers/vue_test_utils_helper';
import ToolbarMoreDropdown from '~/content_editor/components/toolbar_more_dropdown.vue';
import Diagram from '~/content_editor/extensions/diagram';
import HorizontalRule from '~/content_editor/extensions/horizontal_rule';
import { createTestEditor, mockChainedCommands } from '../test_utils';

describe('content_editor/components/toolbar_more_dropdown', () => {
  let wrapper;
  let tiptapEditor;

  const buildEditor = () => {
    tiptapEditor = createTestEditor({
      extensions: [Diagram, HorizontalRule],
    });
  };

  const buildWrapper = (propsData = {}) => {
    wrapper = mountExtended(ToolbarMoreDropdown, {
      provide: {
        tiptapEditor,
      },
      propsData,
    });
  };

  beforeEach(() => {
    buildEditor();
    buildWrapper();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  describe.each`
    label                 | contentType         | data
    ${'Mermaid diagram'}  | ${'diagram'}        | ${{ language: 'mermaid' }}
    ${'PlantUML diagram'} | ${'diagram'}        | ${{ language: 'plantuml' }}
    ${'Horizontal rule'}  | ${'horizontalRule'} | ${undefined}
  `('when option $label is clicked', ({ label, contentType, data }) => {
    it(`inserts a ${contentType}`, async () => {
      const commands = mockChainedCommands(tiptapEditor, ['setNode', 'focus', 'run']);

      const btn = wrapper.findByRole('menuitem', { name: label });
      await btn.trigger('click');

      expect(commands.focus).toHaveBeenCalled();
      expect(commands.setNode).toHaveBeenCalledWith(contentType, data);
      expect(commands.run).toHaveBeenCalled();

      expect(wrapper.emitted('execute')).toEqual([[{ contentType }]]);
    });
  });
});

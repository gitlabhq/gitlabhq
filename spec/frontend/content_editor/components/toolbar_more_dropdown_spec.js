import { GlDisclosureDropdown } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import ToolbarMoreDropdown from '~/content_editor/components/toolbar_more_dropdown.vue';
import Diagram from '~/content_editor/extensions/diagram';
import HorizontalRule from '~/content_editor/extensions/horizontal_rule';
import eventHubFactory from '~/helpers/event_hub_factory';
import { createTestEditor, mockChainedCommands, emitEditorEvent } from '../test_utils';

describe('content_editor/components/toolbar_more_dropdown', () => {
  let wrapper;
  let tiptapEditor;
  let eventHub;

  const buildEditor = () => {
    tiptapEditor = createTestEditor({
      extensions: [Diagram, HorizontalRule],
    });
    eventHub = eventHubFactory();
  };

  const buildWrapper = (propsData = {}) => {
    wrapper = mountExtended(ToolbarMoreDropdown, {
      provide: {
        tiptapEditor,
        eventHub,
      },
      propsData,
    });
  };

  const findDropdown = () => wrapper.findComponent(GlDisclosureDropdown);

  beforeEach(() => {
    buildEditor();
    buildWrapper();
  });

  describe.each`
    name                        | contentType          | command                    | params
    ${'Code block'}             | ${'codeBlock'}       | ${'setNode'}               | ${['codeBlock']}
    ${'Details block'}          | ${'details'}         | ${'toggleList'}            | ${['details', 'detailsContent']}
    ${'Bullet list'}            | ${'bulletList'}      | ${'toggleList'}            | ${['bulletList', 'listItem']}
    ${'Ordered list'}           | ${'orderedList'}     | ${'toggleList'}            | ${['orderedList', 'listItem']}
    ${'Task list'}              | ${'taskList'}        | ${'toggleList'}            | ${['taskList', 'taskItem']}
    ${'Mermaid diagram'}        | ${'diagram'}         | ${'setNode'}               | ${['diagram', { language: 'mermaid' }]}
    ${'PlantUML diagram'}       | ${'diagram'}         | ${'setNode'}               | ${['diagram', { language: 'plantuml' }]}
    ${'Table of contents'}      | ${'tableOfContents'} | ${'insertTableOfContents'} | ${[]}
    ${'Horizontal rule'}        | ${'horizontalRule'}  | ${'setHorizontalRule'}     | ${[]}
    ${'Create or edit diagram'} | ${'drawioDiagram'}   | ${'createOrEditDiagram'}   | ${[]}
  `('when option $name is clicked', ({ name, command, contentType, params }) => {
    let commands;
    let btn;

    beforeEach(async () => {
      commands = mockChainedCommands(tiptapEditor, [command, 'focus', 'run']);
      btn = wrapper.findByRole('button', { name });
    });

    it(`inserts a ${contentType}`, async () => {
      await btn.trigger('click');
      await emitEditorEvent({ event: 'transaction', tiptapEditor });

      expect(commands.focus).toHaveBeenCalled();
      expect(commands[command]).toHaveBeenCalledWith(...params);
      expect(commands.run).toHaveBeenCalled();

      expect(wrapper.emitted('execute')).toEqual([[{ contentType }]]);
    });
  });

  describe('a11y tests', () => {
    it('sets toggleText and text-sr-only properties to the table button dropdown', () => {
      expect(findDropdown().props()).toMatchObject({
        textSrOnly: true,
        toggleText: 'More options',
      });
    });
  });
});

import { nextTick } from 'vue';
import { GlDisclosureDropdown, GlBadge, GlPopover } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import ToolbarMoreDropdown from '~/content_editor/components/toolbar_more_dropdown.vue';
import Diagram from '~/content_editor/extensions/diagram';
import HorizontalRule from '~/content_editor/extensions/horizontal_rule';
import eventHubFactory from '~/helpers/event_hub_factory';
import { useLocalStorageSpy } from 'helpers/local_storage_helper';
import { createTestEditor, mockChainedCommands, emitEditorEvent } from '../test_utils';

describe('content_editor/components/toolbar_more_dropdown', () => {
  useLocalStorageSpy();

  let wrapper;
  let tiptapEditor;
  let contentEditor;
  let eventHub;

  const buildEditor = () => {
    tiptapEditor = createTestEditor({
      extensions: [Diagram, HorizontalRule],
    });
    contentEditor = { drawioEnabled: true };
    eventHub = eventHubFactory();
  };

  const buildWrapper = (propsData = {}) => {
    wrapper = mountExtended(ToolbarMoreDropdown, {
      provide: {
        tiptapEditor,
        contentEditor,
        eventHub,
      },
      propsData,
    });
  };

  const findDropdown = () => wrapper.findComponent(GlDisclosureDropdown);

  beforeEach(() => {
    buildEditor();
  });

  describe.each`
    name                        | contentType          | command                    | params
    ${'Alert'}                  | ${'alert'}           | ${'insertAlert'}           | ${[]}
    ${'Code block'}             | ${'codeBlock'}       | ${'setNode'}               | ${['codeBlock']}
    ${'Collapsible section'}    | ${'details'}         | ${'toggleList'}            | ${['details', 'detailsContent']}
    ${'Bullet list'}            | ${'bulletList'}      | ${'toggleList'}            | ${['bulletList', 'listItem']}
    ${'Ordered list'}           | ${'orderedList'}     | ${'toggleList'}            | ${['orderedList', 'listItem']}
    ${'Task list'}              | ${'taskList'}        | ${'toggleList'}            | ${['taskList', 'taskItem']}
    ${'Mermaid diagram'}        | ${'diagram'}         | ${'insertMermaid'}         | ${[]}
    ${'PlantUML diagram'}       | ${'diagram'}         | ${'insertPlantUML'}        | ${[]}
    ${'Table of contents'}      | ${'tableOfContents'} | ${'insertTableOfContents'} | ${[]}
    ${'Horizontal rule'}        | ${'horizontalRule'}  | ${'setHorizontalRule'}     | ${[]}
    ${'Create or edit diagram'} | ${'drawioDiagram'}   | ${'createOrEditDiagram'}   | ${[]}
    ${'Embedded view New'}      | ${'glqlView'}        | ${'insertGLQLView'}        | ${[]}
  `('when option $name is clicked', ({ name, command, contentType, params }) => {
    let commands;
    let btn;

    beforeEach(() => {
      buildWrapper();

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

  it('does not show drawio option when drawio is disabled', () => {
    contentEditor.drawioEnabled = false;
    buildWrapper();

    expect(wrapper.findByRole('button', { name: 'Create or edit diagram' }).exists()).toBe(false);
  });

  describe('a11y tests', () => {
    it('sets toggleText and text-sr-only properties to the table button dropdown', () => {
      buildWrapper();

      expect(findDropdown().props()).toMatchObject({
        textSrOnly: true,
        toggleText: 'More options',
      });
    });
  });

  it('shows a "New" badge for the embedded view option', () => {
    buildWrapper();

    const btn = wrapper.findByRole('button', { name: 'Embedded view New' });
    const badge = wrapper.findComponent(GlBadge);

    expect(btn.exists()).toBe(true);
    expect(badge.props()).toMatchObject({
      variant: 'info',
      target: '_blank',
      href: '/help/user/glql/_index',
    });
    expect(badge.text()).toBe('New');
  });

  it('shows a GLQL popover that is visible on editor focus', async () => {
    buildWrapper();
    await emitEditorEvent({ event: 'focus', tiptapEditor });

    expect(wrapper.text()).toContain('Introducing embedded views');
  });

  it('saves the value in local storage when popover is hidden', async () => {
    buildWrapper();
    await emitEditorEvent({ event: 'focus', tiptapEditor });

    await wrapper.findComponent(GlPopover).vm.$emit('hidden');

    expect(localStorage.getItem('glql-popover-visible')).toBe('false');
  });

  it('does not show the popover by default if local storage value is false', async () => {
    localStorage.setItem('glql-popover-visible', 'false');

    buildWrapper();
    await emitEditorEvent({ event: 'focus', tiptapEditor });
    await nextTick();

    expect(wrapper.text()).not.toContain('Introducing embedded views');
  });
});

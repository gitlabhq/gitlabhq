import { builders } from 'prosemirror-test-builder';
import { nextTick } from 'vue';
import { NodeViewWrapper } from '@tiptap/vue-2';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import { stubComponent } from 'helpers/stub_component';
import eventHubFactory from '~/helpers/event_hub_factory';
import Heading from '~/content_editor/extensions/heading';
import Diagram from '~/content_editor/extensions/diagram';
import TableOfContentsWrapper from '~/content_editor/components/wrappers/table_of_contents.vue';
import { createTestEditor, emitEditorEvent } from '../../test_utils';

describe('content/components/wrappers/table_of_contents', () => {
  let wrapper;
  let tiptapEditor;
  let contentEditor;
  let eventHub;

  const buildEditor = () => {
    tiptapEditor = createTestEditor({ extensions: [Heading, Diagram] });
    contentEditor = { renderDiagram: jest.fn().mockResolvedValue('url/to/some/diagram') };
    eventHub = eventHubFactory();
  };

  const createWrapper = () => {
    wrapper = mountExtended(TableOfContentsWrapper, {
      propsData: {
        editor: tiptapEditor,
        node: {
          attrs: {},
        },
      },
      stubs: {
        NodeViewWrapper: stubComponent(NodeViewWrapper),
      },
      provide: {
        contentEditor,
        tiptapEditor,
        eventHub,
      },
    });
  };

  beforeEach(async () => {
    buildEditor();
    createWrapper();

    const { heading, doc } = builders(tiptapEditor.schema);

    const initialDoc = doc(
      heading({ level: 1 }, 'Heading 1'),
      heading({ level: 2 }, 'Heading 1.1'),
      heading({ level: 3 }, 'Heading 1.1.1'),
      heading({ level: 2 }, 'Heading 1.2'),
      heading({ level: 3 }, 'Heading 1.2.1'),
      heading({ level: 2 }, 'Heading 1.3'),
      heading({ level: 2 }, 'Heading 1.4'),
      heading({ level: 3 }, 'Heading 1.4.1'),
      heading({ level: 1 }, 'Heading 2'),
    );

    tiptapEditor.commands.setContent(initialDoc.toJSON());

    await emitEditorEvent({ event: 'update', tiptapEditor });
    await nextTick();
  });

  it('renders a node-view-wrapper as a ul element', () => {
    expect(wrapper.findComponent(NodeViewWrapper).props().as).toBe('ul');
  });

  it('collects all headings and renders a nested list of headings', () => {
    expect(wrapper.findComponent(NodeViewWrapper).element).toMatchSnapshot();
  });
});

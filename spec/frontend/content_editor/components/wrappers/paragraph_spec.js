import { NodeViewWrapper, NodeViewContent } from '@tiptap/vue-2';
import { nextTick } from 'vue';
import { stubComponent } from 'helpers/stub_component';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import eventHubFactory from '~/helpers/event_hub_factory';
import ParagraphWrapper from '~/content_editor/components/wrappers/paragraph.vue';
import { createTestEditor, emitEditorEvent } from '../../test_utils';

describe('content/components/wrappers/paragraph', () => {
  let wrapper;
  let tiptapEditor;
  let contentEditor;
  let eventHub;

  const buildEditor = () => {
    tiptapEditor = createTestEditor();
    contentEditor = {
      serializer: {
        serialize: jest.fn(),
      },
      explainQuickAction: jest.fn(),
    };
    eventHub = eventHubFactory();
  };

  const createWrapper = (node) => {
    document.body.innerHTML = `<div class="ProseMirror"><div id="paragraph-wrapper"></div></div>`;

    wrapper = mountExtended(ParagraphWrapper, {
      propsData: {
        node,
      },
      provide: {
        contentEditor,
        tiptapEditor,
        eventHub,
      },
      stubs: {
        NodeViewContent: stubComponent(NodeViewContent, {
          template: `<div>${node.content}</div>`,
        }),
        NodeViewWrapper: stubComponent(NodeViewWrapper),
      },
      attachTo: '#paragraph-wrapper',
    });
  };

  beforeEach(() => {
    buildEditor();
  });

  it('renders an explanation of quick actions if it contains quick actions', async () => {
    contentEditor.serializer.serialize.mockReturnValue('/label ~foo ~bar');
    contentEditor.explainQuickAction.mockReturnValue('Adds 2 labels.');

    createWrapper({ content: '/label ~foo ~bar' });

    await emitEditorEvent({ event: 'transaction', tiptapEditor });
    await nextTick();

    expect(wrapper.text()).toContain('· Adds 2 labels.');
  });

  it('does not render an explanation of quick actions if it does not contain quick actions', async () => {
    contentEditor.serializer.serialize.mockReturnValue('Hello, world!');

    createWrapper({ content: 'Hello, world!' });

    await emitEditorEvent({ event: 'transaction', tiptapEditor });
    await nextTick();

    expect(wrapper.text()).not.toContain('·');
  });
});

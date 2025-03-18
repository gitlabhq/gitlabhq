import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import eventHubFactory from '~/helpers/event_hub_factory';
import AlertTitle from '~/content_editor/components/wrappers/alert_title.vue';
import { ALERT_TYPES, DEFAULT_ALERT_TITLES } from '~/content_editor/constants/alert_types';
import EditorStateObserver from '~/content_editor/components/editor_state_observer.vue';
import { createTestEditor, emitEditorEvent } from '../../test_utils';

describe('content/components/wrappers/alert_title', () => {
  let wrapper;
  let tiptapEditor;
  let contentEditor;
  let eventHub;
  let alert;

  const buildEditor = () => {
    tiptapEditor = createTestEditor();
    contentEditor = {};
    eventHub = eventHubFactory();
  };

  const createWrapper = (node, alertType = ALERT_TYPES.NOTE) => {
    document.body.innerHTML = `<div class="ProseMirror"><div class="markdown-alert markdown-alert-${alertType}"><div id="alert-title-wrapper"></div></div></div>`;

    alert = document.getElementById('alert-title-wrapper').parentElement;

    wrapper = shallowMountExtended(AlertTitle, {
      propsData: {
        node,
      },
      provide: {
        contentEditor,
        tiptapEditor,
        eventHub,
      },
      stubs: {
        EditorStateObserver,
      },
      attachTo: '#alert-title-wrapper',
    });
  };

  beforeEach(() => {
    buildEditor();
  });

  it('renders default title when the node is empty', async () => {
    createWrapper({ content: '', childCount: 0 });

    await emitEditorEvent({ event: 'transaction', tiptapEditor });

    expect(wrapper.find('.markdown-alert-title').text()).toBe(
      DEFAULT_ALERT_TITLES[ALERT_TYPES.NOTE],
    );
  });

  it('does not render default title when the node has content', async () => {
    createWrapper({ content: 'Custom Title', childCount: 1 });

    await emitEditorEvent({ event: 'transaction', tiptapEditor });

    expect(wrapper.find('.markdown-alert-title').text()).toBe('');
  });

  it.each(Object.values(ALERT_TYPES))(
    'updates alert type to %s when parent element has corresponding class',
    async (alertType) => {
      createWrapper({ content: '', childCount: 0 }, alertType);

      alert.className = `markdown-alert markdown-alert-${alertType}`;
      await emitEditorEvent({ event: 'transaction', tiptapEditor });

      expect(wrapper.find('.markdown-alert-title').text()).toBe(DEFAULT_ALERT_TITLES[alertType]);
    },
  );
});

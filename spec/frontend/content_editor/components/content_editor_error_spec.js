import { GlAlert } from '@gitlab/ui';
import { nextTick } from 'vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import ContentEditorError from '~/content_editor/components/content_editor_error.vue';
import EditorStateObserver from '~/content_editor/components/editor_state_observer.vue';
import { createTestEditor, emitEditorEvent } from '../test_utils';

describe('content_editor/components/content_editor_error', () => {
  let wrapper;
  let tiptapEditor;

  const findErrorAlert = () => wrapper.findComponent(GlAlert);

  const createWrapper = async () => {
    tiptapEditor = createTestEditor();

    wrapper = shallowMountExtended(ContentEditorError, {
      provide: {
        tiptapEditor,
      },
      stubs: {
        EditorStateObserver,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  it('renders error when content editor emits an error event', async () => {
    const error = 'error message';

    createWrapper();

    await emitEditorEvent({ tiptapEditor, event: 'error', params: { error } });

    expect(findErrorAlert().text()).toBe(error);
  });

  it('allows dismissing the error', async () => {
    const error = 'error message';

    createWrapper();

    await emitEditorEvent({ tiptapEditor, event: 'error', params: { error } });

    findErrorAlert().vm.$emit('dismiss');

    await nextTick();

    expect(findErrorAlert().exists()).toBe(false);
  });
});

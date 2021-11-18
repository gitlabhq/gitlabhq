import { GlAlert } from '@gitlab/ui';
import { nextTick } from 'vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import ContentEditorAlert from '~/content_editor/components/content_editor_alert.vue';
import EditorStateObserver from '~/content_editor/components/editor_state_observer.vue';
import { createTestEditor, emitEditorEvent } from '../test_utils';

describe('content_editor/components/content_editor_alert', () => {
  let wrapper;
  let tiptapEditor;

  const findErrorAlert = () => wrapper.findComponent(GlAlert);

  const createWrapper = async () => {
    tiptapEditor = createTestEditor();

    wrapper = shallowMountExtended(ContentEditorAlert, {
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

  it.each`
    variant      | message
    ${'danger'}  | ${'An error occurred'}
    ${'warning'} | ${'A warning'}
  `(
    'renders error when content editor emits an error event for variant: $variant',
    async ({ message, variant }) => {
      createWrapper();

      await emitEditorEvent({ tiptapEditor, event: 'alert', params: { message, variant } });

      expect(findErrorAlert().text()).toBe(message);
      expect(findErrorAlert().attributes().variant).toBe(variant);
    },
  );

  it('allows dismissing the error', async () => {
    const message = 'error message';

    createWrapper();

    await emitEditorEvent({ tiptapEditor, event: 'alert', params: { message } });

    findErrorAlert().vm.$emit('dismiss');

    await nextTick();

    expect(findErrorAlert().exists()).toBe(false);
  });
});

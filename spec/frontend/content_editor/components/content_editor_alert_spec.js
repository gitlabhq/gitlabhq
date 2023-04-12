import { GlAlert } from '@gitlab/ui';
import { nextTick } from 'vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import ContentEditorAlert from '~/content_editor/components/content_editor_alert.vue';
import EditorStateObserver from '~/content_editor/components/editor_state_observer.vue';
import eventHubFactory from '~/helpers/event_hub_factory';
import { ALERT_EVENT } from '~/content_editor/constants';
import { createTestEditor } from '../test_utils';

describe('content_editor/components/content_editor_alert', () => {
  let wrapper;
  let tiptapEditor;
  let eventHub;

  const findErrorAlert = () => wrapper.findComponent(GlAlert);

  const createWrapper = () => {
    tiptapEditor = createTestEditor();
    eventHub = eventHubFactory();

    wrapper = shallowMountExtended(ContentEditorAlert, {
      provide: {
        tiptapEditor,
        eventHub,
      },
      stubs: {
        EditorStateObserver,
      },
    });
  };

  it.each`
    variant      | message
    ${'danger'}  | ${'An error occurred'}
    ${'warning'} | ${'A warning'}
  `(
    'renders error when content editor emits an error event for variant: $variant',
    async ({ message, variant }) => {
      createWrapper();

      eventHub.$emit(ALERT_EVENT, { message, variant });

      await nextTick();

      expect(findErrorAlert().text()).toBe(message);
      expect(findErrorAlert().attributes().variant).toBe(variant);
    },
  );

  it('does not show primary action by default', async () => {
    const message = 'error message';

    createWrapper();
    eventHub.$emit(ALERT_EVENT, { message });
    await nextTick();

    expect(findErrorAlert().attributes().primaryButtonText).toBeUndefined();
  });

  it('allows dismissing the error', async () => {
    const message = 'error message';

    createWrapper();
    eventHub.$emit(ALERT_EVENT, { message });
    await nextTick();
    findErrorAlert().vm.$emit('dismiss');
    await nextTick();

    expect(findErrorAlert().exists()).toBe(false);
  });

  it('allows dismissing the error with a primary action button', async () => {
    const message = 'error message';
    const actionLabel = 'Retry';
    const action = jest.fn();

    createWrapper();
    eventHub.$emit(ALERT_EVENT, { message, action, actionLabel });
    await nextTick();
    findErrorAlert().vm.$emit('primaryAction');
    await nextTick();

    expect(action).toHaveBeenCalled();
    expect(findErrorAlert().exists()).toBe(false);
  });
});

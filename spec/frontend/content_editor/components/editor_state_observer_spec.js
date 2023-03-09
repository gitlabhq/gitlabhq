import { shallowMount } from '@vue/test-utils';
import { each } from 'lodash';
import EditorStateObserver, {
  tiptapToComponentMap,
} from '~/content_editor/components/editor_state_observer.vue';
import eventHubFactory from '~/helpers/event_hub_factory';
import { ALERT_EVENT, KEYDOWN_EVENT } from '~/content_editor/constants';
import { createTestEditor } from '../test_utils';

describe('content_editor/components/editor_state_observer', () => {
  let tiptapEditor;
  let wrapper;
  let onDocUpdateListener;
  let onSelectionUpdateListener;
  let onTransactionListener;
  let onAlertListener;
  let onKeydownListener;
  let eventHub;

  const buildEditor = () => {
    tiptapEditor = createTestEditor();
    eventHub = eventHubFactory();
    jest.spyOn(tiptapEditor, 'on');
  };

  const buildWrapper = () => {
    wrapper = shallowMount(EditorStateObserver, {
      provide: { tiptapEditor, eventHub },
      listeners: {
        docUpdate: onDocUpdateListener,
        selectionUpdate: onSelectionUpdateListener,
        transaction: onTransactionListener,
        [ALERT_EVENT]: onAlertListener,
        [KEYDOWN_EVENT]: onKeydownListener,
      },
    });
  };

  beforeEach(() => {
    onDocUpdateListener = jest.fn();
    onSelectionUpdateListener = jest.fn();
    onTransactionListener = jest.fn();
    onAlertListener = jest.fn();
    onKeydownListener = jest.fn();
    buildEditor();
  });

  describe('when editor content changes', () => {
    it('emits update, selectionUpdate, and transaction events', () => {
      const content = '<p>My paragraph</p>';

      buildWrapper();

      tiptapEditor.commands.insertContent(content);

      expect(onDocUpdateListener).toHaveBeenCalledWith(
        expect.objectContaining({ editor: tiptapEditor }),
      );
      expect(onSelectionUpdateListener).toHaveBeenCalledWith(
        expect.objectContaining({ editor: tiptapEditor }),
      );
      expect(onSelectionUpdateListener).toHaveBeenCalledWith(
        expect.objectContaining({ editor: tiptapEditor }),
      );
    });
  });

  it.each`
    event            | listener
    ${ALERT_EVENT}   | ${() => onAlertListener}
    ${KEYDOWN_EVENT} | ${() => onKeydownListener}
  `('listens to $event event in the eventBus object', ({ event, listener }) => {
    const args = {};

    buildWrapper();

    eventHub.$emit(event, args);
    expect(listener()).toHaveBeenCalledWith(args);
  });

  describe('when component is destroyed', () => {
    it('removes onTiptapDocUpdate and onTiptapSelectionUpdate hooks', () => {
      jest.spyOn(tiptapEditor, 'off');

      buildWrapper();

      wrapper.destroy();

      each(tiptapToComponentMap, (_, tiptapEvent) => {
        expect(tiptapEditor.off).toHaveBeenCalledWith(
          tiptapEvent,
          tiptapEditor.on.mock.calls.find(([eventName]) => eventName === tiptapEvent)[1],
        );
      });
    });

    it.each`
      event
      ${ALERT_EVENT}
      ${KEYDOWN_EVENT}
    `('removes $event event hook from eventHub', ({ event }) => {
      jest.spyOn(eventHub, '$off');
      jest.spyOn(eventHub, '$on');

      buildWrapper();

      wrapper.destroy();

      expect(eventHub.$off).toHaveBeenCalledWith(
        event,
        eventHub.$on.mock.calls.find(([eventName]) => eventName === event)[1],
      );
    });
  });
});

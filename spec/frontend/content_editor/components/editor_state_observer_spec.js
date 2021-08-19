import { shallowMount } from '@vue/test-utils';
import { each } from 'lodash';
import EditorStateObserver, {
  tiptapToComponentMap,
} from '~/content_editor/components/editor_state_observer.vue';
import { createTestEditor } from '../test_utils';

describe('content_editor/components/editor_state_observer', () => {
  let tiptapEditor;
  let wrapper;
  let onDocUpdateListener;
  let onSelectionUpdateListener;
  let onTransactionListener;

  const buildEditor = () => {
    tiptapEditor = createTestEditor();
    jest.spyOn(tiptapEditor, 'on');
  };

  const buildWrapper = () => {
    wrapper = shallowMount(EditorStateObserver, {
      provide: { tiptapEditor },
      listeners: {
        docUpdate: onDocUpdateListener,
        selectionUpdate: onSelectionUpdateListener,
        transaction: onTransactionListener,
      },
    });
  };

  beforeEach(() => {
    onDocUpdateListener = jest.fn();
    onSelectionUpdateListener = jest.fn();
    onTransactionListener = jest.fn();
    buildEditor();
    buildWrapper();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  describe('when editor content changes', () => {
    it('emits update, selectionUpdate, and transaction events', () => {
      const content = '<p>My paragraph</p>';

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

  describe('when component is destroyed', () => {
    it('removes onTiptapDocUpdate and onTiptapSelectionUpdate hooks', () => {
      jest.spyOn(tiptapEditor, 'off');

      wrapper.destroy();

      each(tiptapToComponentMap, (_, tiptapEvent) => {
        expect(tiptapEditor.off).toHaveBeenCalledWith(
          tiptapEvent,
          tiptapEditor.on.mock.calls.find(([eventName]) => eventName === tiptapEvent)[1],
        );
      });
    });
  });
});

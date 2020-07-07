import { shallowMount } from '@vue/test-utils';
import RichContentEditor from '~/vue_shared/components/rich_content_editor/rich_content_editor.vue';
import AddImageModal from '~/vue_shared/components/rich_content_editor/modals/add_image/add_image_modal.vue';
import {
  EDITOR_OPTIONS,
  EDITOR_TYPES,
  EDITOR_HEIGHT,
  EDITOR_PREVIEW_STYLE,
  CUSTOM_EVENTS,
} from '~/vue_shared/components/rich_content_editor/constants';

import {
  addCustomEventListener,
  removeCustomEventListener,
  addImage,
  registerHTMLToMarkdownRenderer,
} from '~/vue_shared/components/rich_content_editor/services/editor_service';

jest.mock('~/vue_shared/components/rich_content_editor/services/editor_service', () => ({
  ...jest.requireActual('~/vue_shared/components/rich_content_editor/services/editor_service'),
  addCustomEventListener: jest.fn(),
  removeCustomEventListener: jest.fn(),
  addImage: jest.fn(),
  registerHTMLToMarkdownRenderer: jest.fn(),
}));

describe('Rich Content Editor', () => {
  let wrapper;

  const content = '## Some Markdown';
  const findEditor = () => wrapper.find({ ref: 'editor' });
  const findAddImageModal = () => wrapper.find(AddImageModal);

  beforeEach(() => {
    wrapper = shallowMount(RichContentEditor, {
      propsData: { content },
    });
  });

  describe('when content is loaded', () => {
    it('renders an editor', () => {
      expect(findEditor().exists()).toBe(true);
    });

    it('renders the correct content', () => {
      expect(findEditor().props().initialValue).toBe(content);
    });

    it('provides the correct editor options', () => {
      expect(findEditor().props().options).toEqual(EDITOR_OPTIONS);
    });

    it('has the correct preview style', () => {
      expect(findEditor().props().previewStyle).toBe(EDITOR_PREVIEW_STYLE);
    });

    it('has the correct initial edit type', () => {
      expect(findEditor().props().initialEditType).toBe(EDITOR_TYPES.wysiwyg);
    });

    it('has the correct height', () => {
      expect(findEditor().props().height).toBe(EDITOR_HEIGHT);
    });
  });

  describe('when content is changed', () => {
    it('emits an input event with the changed content', () => {
      const changedMarkdown = '## Changed Markdown';
      const getMarkdownMock = jest.fn().mockReturnValueOnce(changedMarkdown);

      findEditor().setMethods({ invoke: getMarkdownMock });
      findEditor().vm.$emit('change');

      expect(wrapper.emitted().input[0][0]).toBe(changedMarkdown);
    });
  });

  describe('when content is reset', () => {
    it('should reset the content via setMarkdown', () => {
      const newContent = 'Just the body content excluding the front matter for example';
      const mockInstance = { invoke: jest.fn() };
      wrapper.vm.$refs.editor = mockInstance;

      wrapper.vm.resetInitialValue(newContent);

      expect(mockInstance.invoke).toHaveBeenCalledWith('setMarkdown', newContent);
    });
  });

  describe('when editor is loaded', () => {
    let mockEditorApi;

    beforeEach(() => {
      mockEditorApi = { eventManager: { addEventType: jest.fn(), listen: jest.fn() } };
      findEditor().vm.$emit('load', mockEditorApi);
    });

    it('adds the CUSTOM_EVENTS.openAddImageModal custom event listener', () => {
      expect(addCustomEventListener).toHaveBeenCalledWith(
        mockEditorApi,
        CUSTOM_EVENTS.openAddImageModal,
        wrapper.vm.onOpenAddImageModal,
      );
    });

    it('registers HTML to markdown renderer', () => {
      expect(registerHTMLToMarkdownRenderer).toHaveBeenCalledWith(mockEditorApi);
    });
  });

  describe('when editor is destroyed', () => {
    it('removes the CUSTOM_EVENTS.openAddImageModal custom event listener', () => {
      const mockEditorApi = { eventManager: { removeEventHandler: jest.fn() } };

      wrapper.vm.editorApi = mockEditorApi;
      wrapper.vm.$destroy();

      expect(removeCustomEventListener).toHaveBeenCalledWith(
        mockEditorApi,
        CUSTOM_EVENTS.openAddImageModal,
        wrapper.vm.onOpenAddImageModal,
      );
    });
  });

  describe('add image modal', () => {
    it('renders an addImageModal component', () => {
      expect(findAddImageModal().exists()).toBe(true);
    });

    it('calls the onAddImage method when the addImage event is emitted', () => {
      const mockImage = { imageUrl: 'some/url.png', altText: 'some description' };
      const mockInstance = { exec: jest.fn() };
      wrapper.vm.$refs.editor = mockInstance;

      findAddImageModal().vm.$emit('addImage', mockImage);
      expect(addImage).toHaveBeenCalledWith(mockInstance, mockImage);
    });
  });
});

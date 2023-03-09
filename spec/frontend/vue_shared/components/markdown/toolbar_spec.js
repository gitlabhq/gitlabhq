import { mount } from '@vue/test-utils';
import Toolbar from '~/vue_shared/components/markdown/toolbar.vue';
import EditorModeDropdown from '~/vue_shared/components/markdown/editor_mode_dropdown.vue';

describe('toolbar', () => {
  let wrapper;

  const createMountedWrapper = (props = {}) => {
    wrapper = mount(Toolbar, {
      propsData: { markdownDocsPath: '', ...props },
    });
  };

  describe('user can attach file', () => {
    beforeEach(() => {
      createMountedWrapper();
    });

    it('should render uploading-container', () => {
      expect(wrapper.vm.$el.querySelector('.uploading-container')).not.toBeNull();
    });
  });

  describe('user cannot attach file', () => {
    beforeEach(() => {
      createMountedWrapper({ canAttachFile: false });
    });

    it('should not render uploading-container', () => {
      expect(wrapper.vm.$el.querySelector('.uploading-container')).toBeNull();
    });
  });

  describe('comment tool bar settings', () => {
    it('does not show comment tool bar div', () => {
      createMountedWrapper({ showCommentToolBar: false });

      expect(wrapper.find('.comment-toolbar').exists()).toBe(false);
    });

    it('shows comment tool bar by default', () => {
      createMountedWrapper();

      expect(wrapper.find('.comment-toolbar').exists()).toBe(true);
    });
  });

  describe('with content editor switcher', () => {
    beforeEach(() => {
      createMountedWrapper({
        showContentEditorSwitcher: true,
      });
    });

    it('re-emits event from switcher', () => {
      wrapper.findComponent(EditorModeDropdown).vm.$emit('input', 'richText');

      expect(wrapper.emitted('enableContentEditor')).toEqual([[]]);
    });
  });
});

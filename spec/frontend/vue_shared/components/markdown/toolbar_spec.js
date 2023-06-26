import { mount } from '@vue/test-utils';
import Toolbar from '~/vue_shared/components/markdown/toolbar.vue';
import EditorModeSwitcher from '~/vue_shared/components/markdown/editor_mode_switcher.vue';

describe('toolbar', () => {
  let wrapper;

  const createWrapper = (props = {}) => {
    wrapper = mount(Toolbar, {
      propsData: { markdownDocsPath: '', ...props },
    });
  };

  describe('user can attach file', () => {
    beforeEach(() => {
      createWrapper();
    });

    it('should render uploading-container', () => {
      expect(wrapper.vm.$el.querySelector('.uploading-container')).not.toBeNull();
    });
  });

  describe('user cannot attach file', () => {
    beforeEach(() => {
      createWrapper({ canAttachFile: false });
    });

    it('should not render uploading-container', () => {
      expect(wrapper.vm.$el.querySelector('.uploading-container')).toBeNull();
    });
  });

  describe('comment tool bar settings', () => {
    it('does not show comment tool bar div', () => {
      createWrapper({ showCommentToolBar: false });

      expect(wrapper.find('.comment-toolbar').exists()).toBe(false);
    });

    it('shows comment tool bar by default', () => {
      createWrapper();

      expect(wrapper.find('.comment-toolbar').exists()).toBe(true);
    });
  });

  describe('with content editor switcher', () => {
    beforeEach(() => {
      createWrapper({
        showContentEditorSwitcher: true,
      });
    });

    it('re-emits event from switcher', () => {
      wrapper.findComponent(EditorModeSwitcher).vm.$emit('input', 'richText');

      expect(wrapper.emitted('enableContentEditor')).toEqual([[]]);
    });
  });
});

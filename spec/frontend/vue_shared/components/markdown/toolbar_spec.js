import { mount } from '@vue/test-utils';
import Toolbar from '~/vue_shared/components/markdown/toolbar.vue';
import EditorModeSwitcher from '~/vue_shared/components/markdown/editor_mode_switcher.vue';
import { updateText } from '~/lib/utils/text_markdown';
import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';

jest.mock('~/lib/utils/text_markdown');

describe('toolbar', () => {
  let wrapper;

  const createWrapper = (props = {}, attachTo = document.body) => {
    wrapper = mount(Toolbar, {
      attachTo,
      propsData: { markdownDocsPath: '', ...props },
      mocks: {
        $apollo: {
          queries: {
            currentUser: {
              loading: false,
            },
          },
        },
      },
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
      setHTMLFixture(
        '<div class="md-area"><textarea>some value</textarea><div id="root"></div></div>',
      );
      createWrapper(
        {
          showContentEditorSwitcher: true,
        },
        '#root',
      );
    });

    afterEach(() => {
      resetHTMLFixture();
    });

    it('re-emits event from switcher', () => {
      wrapper.findComponent(EditorModeSwitcher).vm.$emit('switch');

      expect(wrapper.emitted('enableContentEditor')).toEqual([[]]);
      expect(updateText).not.toHaveBeenCalled();
    });
  });
});

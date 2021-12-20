import { mount } from '@vue/test-utils';
import Toolbar from '~/vue_shared/components/markdown/toolbar.vue';

describe('toolbar', () => {
  let wrapper;

  const createMountedWrapper = (props = {}) => {
    wrapper = mount(Toolbar, {
      propsData: { markdownDocsPath: '', ...props },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

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
});

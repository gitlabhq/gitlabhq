import { shallowMount, mount } from '@vue/test-utils';
import ModalCopyButton from '~/vue_shared/components/modal_copy_button.vue';
import EnableReviewAppButton from '~/environments/components/enable_review_app_button.vue';

describe('Enable Review App Button', () => {
  let wrapper;

  afterEach(() => {
    wrapper.destroy();
  });

  describe('renders button with text', () => {
    beforeEach(() => {
      wrapper = mount(EnableReviewAppButton);
    });

    it('renders Enable Review text', () => {
      expect(wrapper.text()).toBe('Enable review app');
    });
  });

  describe('renders the modal', () => {
    beforeEach(() => {
      wrapper = shallowMount(EnableReviewAppButton);
    });

    it('renders the copyToClipboard button', () => {
      expect(wrapper.find(ModalCopyButton).exists()).toBe(true);
    });
  });
});

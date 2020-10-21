import { shallowMount } from '@vue/test-utils';
import ModalCopyButton from '~/vue_shared/components/modal_copy_button.vue';
import EnableReviewAppButton from '~/environments/components/enable_review_app_modal.vue';

describe('Enable Review App Button', () => {
  let wrapper;

  afterEach(() => {
    wrapper.destroy();
  });

  describe('renders the modal', () => {
    beforeEach(() => {
      wrapper = shallowMount(EnableReviewAppButton, {
        propsData: {
          modalId: 'fake-id',
        },
      });
    });

    it('renders the copyToClipboard button', () => {
      expect(wrapper.find(ModalCopyButton).exists()).toBe(true);
    });
  });
});

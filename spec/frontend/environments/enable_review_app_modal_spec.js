import { shallowMount } from '@vue/test-utils';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import EnableReviewAppButton from '~/environments/components/enable_review_app_modal.vue';
import ModalCopyButton from '~/vue_shared/components/modal_copy_button.vue';

describe('Enable Review App Button', () => {
  let wrapper;

  afterEach(() => {
    wrapper.destroy();
  });

  describe('renders the modal', () => {
    beforeEach(() => {
      wrapper = extendedWrapper(
        shallowMount(EnableReviewAppButton, {
          propsData: {
            modalId: 'fake-id',
          },
          provide: {
            defaultBranchName: 'main',
          },
        }),
      );
    });

    it('renders the defaultBranchName copy', () => {
      const findCopyString = () => wrapper.findByTestId('enable-review-app-copy-string');
      expect(findCopyString().text()).toContain('- main');
    });

    it('renders the copyToClipboard button', () => {
      expect(wrapper.findComponent(ModalCopyButton).exists()).toBe(true);
    });
  });
});

import { shallowMount } from '@vue/test-utils';
import { GlModal } from '@gitlab/ui';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import EnableReviewAppButton from '~/environments/components/enable_review_app_modal.vue';
import ModalCopyButton from '~/vue_shared/components/modal_copy_button.vue';

describe('Enable Review App Button', () => {
  let wrapper;
  let modal;

  afterEach(() => {
    wrapper.destroy();
  });

  describe('renders the modal', () => {
    beforeEach(() => {
      wrapper = extendedWrapper(
        shallowMount(EnableReviewAppButton, {
          propsData: {
            modalId: 'fake-id',
            visible: true,
          },
          provide: {
            defaultBranchName: 'main',
          },
        }),
      );

      modal = wrapper.findComponent(GlModal);
    });

    it('renders the defaultBranchName copy', () => {
      const findCopyString = () => wrapper.findByTestId('enable-review-app-copy-string');
      expect(findCopyString().text()).toContain('- main');
    });

    it('renders the copyToClipboard button', () => {
      expect(wrapper.findComponent(ModalCopyButton).exists()).toBe(true);
    });

    it('emits change events from the modal up', () => {
      modal.vm.$emit('change', false);

      expect(wrapper.emitted('change')).toEqual([[false]]);
    });

    it('passes visible to the modal', () => {
      expect(modal.props('visible')).toBe(true);
    });
  });
});

import { shallowMount } from '@vue/test-utils';
import { GlModal } from '@gitlab/ui';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import EnableReviewAppButton from '~/environments/components/enable_review_app_modal.vue';
import ModalCopyButton from '~/vue_shared/components/modal_copy_button.vue';

// hardcode uniqueId for determinism
jest.mock('lodash/uniqueId', () => (x) => `${x}77`);

const EXPECTED_COPY_PRE_ID = 'enable-review-app-copy-string-77';

describe('Enable Review App Button', () => {
  let wrapper;
  let modal;

  const findCopyString = () => wrapper.find(`#${EXPECTED_COPY_PRE_ID}`);

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
      expect(findCopyString().text()).toContain('- main');
    });

    it('renders the copyToClipboard button', () => {
      expect(wrapper.findComponent(ModalCopyButton).props()).toMatchObject({
        modalId: 'fake-id',
        target: `#${EXPECTED_COPY_PRE_ID}`,
        title: 'Copy snippet text',
      });
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

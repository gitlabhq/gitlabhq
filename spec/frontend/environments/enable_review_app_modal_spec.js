import { shallowMount } from '@vue/test-utils';
import { GlModal } from '@gitlab/ui';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import EnableReviewAppModal from '~/environments/components/enable_review_app_modal.vue';
import { REVIEW_APP_MODAL_I18N as i18n } from '~/environments/constants';
import ModalCopyButton from '~/vue_shared/components/modal_copy_button.vue';

// hardcode uniqueId for determinism
jest.mock('lodash/uniqueId', () => (x) => `${x}77`);

const EXPECTED_COPY_PRE_ID = 'enable-review-app-copy-string-77';

describe('Enable Review Apps Modal', () => {
  let wrapper;
  let modal;

  const findInstructions = () => wrapper.findAll('ol li');
  const findInstructionAt = (i) => wrapper.findAll('ol li').at(i);
  const findCopyString = () => wrapper.find(`#${EXPECTED_COPY_PRE_ID}`);

  describe('renders the modal', () => {
    beforeEach(() => {
      wrapper = extendedWrapper(
        shallowMount(EnableReviewAppModal, {
          propsData: {
            modalId: 'fake-id',
            visible: true,
          },
        }),
      );

      modal = wrapper.findComponent(GlModal);
    });

    it('displays instructions', () => {
      expect(findInstructions().length).toBe(7);
      expect(findInstructionAt(0).text()).toContain(i18n.instructions.step1);
    });

    it('renders the snippet to copy', () => {
      expect(findCopyString().text()).toBe(wrapper.vm.modalInfoCopyStr);
    });

    it('renders the copyToClipboard button', () => {
      expect(wrapper.findComponent(ModalCopyButton).props()).toMatchObject({
        modalId: 'fake-id',
        target: `#${EXPECTED_COPY_PRE_ID}`,
        title: i18n.copyToClipboardText,
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

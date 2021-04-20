import { GlModal } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import { stubComponent } from 'helpers/stub_component';
import { TEST_HOST } from 'helpers/test_constants';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import DeleteLabelModal from '~/vue_shared/components/delete_label_modal.vue';

const MOCK_MODAL_DATA = {
  labelName: 'label 1',
  subjectName: 'GitLab Org',
  destroyPath: `${TEST_HOST}/1`,
};

describe('vue_shared/components/delete_label_modal', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = extendedWrapper(
      mount(DeleteLabelModal, {
        propsData: {
          selector: '.js-test-btn',
        },
        stubs: {
          GlModal: stubComponent(GlModal, {
            template:
              '<div><slot name="modal-title"></slot><slot></slot><slot name="modal-footer"></slot></div>',
          }),
        },
      }),
    );
  };

  afterEach(() => {
    wrapper.destroy();
  });

  const findModal = () => wrapper.find(GlModal);
  const findPrimaryModalButton = () => wrapper.findByTestId('delete-button');

  describe('template', () => {
    describe('when modal data is set', () => {
      beforeEach(() => {
        createComponent();
        wrapper.vm.labelName = MOCK_MODAL_DATA.labelName;
        wrapper.vm.subjectName = MOCK_MODAL_DATA.subjectName;
        wrapper.vm.destroyPath = MOCK_MODAL_DATA.destroyPath;
      });

      it('renders GlModal', () => {
        expect(findModal().exists()).toBe(true);
      });

      it('displays the label name and subject name', () => {
        expect(findModal().text()).toContain(
          `${MOCK_MODAL_DATA.labelName} will be permanently deleted from ${MOCK_MODAL_DATA.subjectName}. This cannot be undone`,
        );
      });

      it('passes the destroyPath to the button', () => {
        expect(findPrimaryModalButton().attributes('href')).toBe(MOCK_MODAL_DATA.destroyPath);
      });
    });
  });
});

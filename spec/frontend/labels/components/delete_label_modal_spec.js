import { GlModal } from '@gitlab/ui';
import { stubComponent } from 'helpers/stub_component';
import { TEST_HOST } from 'helpers/test_constants';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import DeleteLabelModal from '~/labels/components/delete_label_modal.vue';

describe('~/labels/components/delete_label_modal', () => {
  let wrapper;

  const mountComponent = () => {
    const button = document.createElement('button');
    button.classList.add('js-test-btn');
    button.dataset.destroyPath = `${TEST_HOST}/1`;
    button.dataset.labelName = 'label 1';
    button.dataset.subjectName = 'GitLab Org';
    document.body.append(button);

    wrapper = mountExtended(DeleteLabelModal, {
      propsData: {
        selector: '.js-test-btn',
      },
      stubs: {
        GlModal: stubComponent(GlModal, {
          template:
            '<div><slot name="modal-title"></slot><slot></slot><slot name="modal-footer"></slot></div>',
        }),
      },
    });

    button.click();
  };

  const findModal = () => wrapper.findComponent(GlModal);
  const findDeleteButton = () => wrapper.findByRole('link', { name: 'Delete label' });

  describe('when modal data is set', () => {
    beforeEach(() => {
      mountComponent();
    });

    it('renders GlModal', () => {
      expect(findModal().exists()).toBe(true);
    });

    it('displays the label name and subject name', () => {
      expect(findModal().text()).toContain(
        `label 1 will be permanently deleted from GitLab Org. This cannot be undone`,
      );
    });

    it('passes the destroyPath to the button', () => {
      expect(findDeleteButton().attributes('href')).toBe('http://test.host/1');
    });
  });
});

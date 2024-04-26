import { GlModal } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import DeleteIssueModal from '~/issues/show/components/delete_issue_modal.vue';

jest.mock('~/lib/utils/csrf', () => ({ token: 'mock-csrf-token' }));

describe('DeleteIssueModal component', () => {
  let wrapper;

  const defaultProps = {
    issuePath: 'gitlab-org/gitlab-test/-/issues/1',
    issueType: 'issue',
    modalId: 'modal-id',
    title: 'Delete issue',
  };

  const findForm = () => wrapper.find('form');
  const findModal = () => wrapper.findComponent(GlModal);

  const mountComponent = (props = {}) =>
    shallowMount(DeleteIssueModal, { propsData: { ...defaultProps, ...props } });

  describe('modal', () => {
    it('renders', () => {
      wrapper = mountComponent();

      expect(findModal().props()).toMatchObject({
        actionCancel: DeleteIssueModal.actionCancel,
        actionPrimary: {
          attributes: { variant: 'danger' },
          text: defaultProps.title,
        },
        modalId: defaultProps.modalId,
        size: 'sm',
        title: defaultProps.title,
      });
    });

    describe('when "primary" event is emitted', () => {
      const submitMock = jest.fn();
      // Mock the form submit method
      Object.defineProperty(HTMLFormElement.prototype, 'submit', {
        value: submitMock,
      });

      beforeEach(() => {
        wrapper = mountComponent();
        findModal().vm.$emit('primary');
      });

      it('"delete" event is emitted by DeleteIssueModal', () => {
        expect(wrapper.emitted('delete')).toEqual([[]]);
      });

      it('submits the form', () => {
        expect(submitMock).toHaveBeenCalledTimes(1);
      });
    });
  });

  describe('form', () => {
    beforeEach(() => {
      wrapper = mountComponent();
    });

    it('renders with action and method', () => {
      expect(findForm().attributes()).toEqual({
        action: defaultProps.issuePath,
        method: 'post',
      });
    });

    it('contains form data', () => {
      const formData = wrapper.findAll('input').wrappers.reduce(
        (acc, input) => ({
          ...acc,
          [input.element.name]: input.element.value,
        }),
        {},
      );

      expect(formData).toEqual({
        _method: 'delete',
        authenticity_token: 'mock-csrf-token',
        destroy_confirm: 'true',
      });
    });
  });

  describe('body text', () => {
    describe('when issue type is not epic', () => {
      it('renders', () => {
        wrapper = mountComponent();

        expect(findForm().text()).toBe('Issue will be removed! Are you sure?');
      });
    });

    describe('when issue type is epic', () => {
      it('renders', () => {
        wrapper = mountComponent({ issueType: 'epic' });

        expect(findForm().text()).toBe('Delete this epic and release all child items?');
      });
    });
  });
});

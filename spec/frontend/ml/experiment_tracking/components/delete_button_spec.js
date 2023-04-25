import { GlModal, GlDisclosureDropdown, GlDisclosureDropdownItem } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import DeleteButton from '~/ml/experiment_tracking/components/delete_button.vue';

const csrfToken = 'mock-csrf-token';
jest.mock('~/lib/utils/csrf', () => ({ token: csrfToken }));

const MODAL_BODY = 'MODAL_BODY';
const MODAL_TITLE = 'MODAL_TITLE';

describe('DeleteButton', () => {
  let wrapper;

  const findModal = () => wrapper.findComponent(GlModal);
  const findDropdown = () => wrapper.findComponent(GlDisclosureDropdown);
  const findDeleteButton = () => wrapper.findComponent(GlDisclosureDropdownItem);
  const findForm = () => wrapper.find('form');
  const findModalText = () => wrapper.findByText(MODAL_BODY);

  beforeEach(() => {
    wrapper = shallowMountExtended(DeleteButton, {
      propsData: {
        deletePath: '/delete',
        deleteConfirmationText: MODAL_BODY,
        actionPrimaryText: 'Delete!',
        modalTitle: MODAL_TITLE,
      },
    });
  });

  it('mounts the modal', () => {
    expect(findModal().exists()).toBe(true);
  });

  it('mounts the dropdown', () => {
    expect(findDropdown().exists()).toBe(true);
  });

  it('mounts the button', () => {
    expect(findDeleteButton().exists()).toBe(true);
  });

  describe('when modal is opened', () => {
    it('displays modal title', () => {
      expect(findModal().props('title')).toBe(MODAL_TITLE);
    });

    it('displays modal body', () => {
      expect(findModalText().exists()).toBe(true);
    });

    it('submits the form when primary action is clicked', () => {
      const submitSpy = jest.spyOn(findForm().element, 'submit');

      findModal().vm.$emit('primary');

      expect(submitSpy).toHaveBeenCalled();
    });

    it('displays form with correct action and inputs', () => {
      const form = findForm();

      expect(form.attributes('action')).toBe('/delete');
      expect(form.find('input[name="_method"]').attributes('value')).toBe('delete');
      expect(form.find('input[name="authenticity_token"]').attributes('value')).toBe(csrfToken);
    });
  });
});

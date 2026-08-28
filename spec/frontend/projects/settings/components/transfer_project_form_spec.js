import { nextTick } from 'vue';
import transferLocationsResponsePage1 from 'test_fixtures/api/projects/transfer_locations_page_1.json';
import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import TransferProjectForm from '~/projects/settings/components/transfer_project_form.vue';
import TransferLocations from '~/groups_projects/components/transfer_locations.vue';
import ConfirmDanger from '~/vue_shared/components/confirm_danger/confirm_danger.vue';
import { getTransferLocations } from '~/api/projects_api';

jest.mock('~/api/projects_api', () => ({
  getTransferLocations: jest.fn(),
}));

describe('Transfer project form', () => {
  let wrapper;

  const resourceId = '1';
  const confirmButtonText = 'Confirm';
  const confirmationPhrase = 'You must construct additional pylons!';
  const targetFormId = 'transfer-project-form';
  const targetHiddenInputId = 'new_namespace_id';

  const createComponent = ({ showUserTransferLocations = true, ...props } = {}) => {
    wrapper = shallowMountExtended(TransferProjectForm, {
      provide: {
        resourceId,
      },
      propsData: {
        confirmButtonText,
        confirmationPhrase,
        showUserTransferLocations,
        targetFormId,
        targetHiddenInputId,
        ...props,
      },
    });
  };

  const findTransferLocations = () => wrapper.findComponent(TransferLocations);
  const findConfirmDanger = () => wrapper.findComponent(ConfirmDanger);

  it('renders the namespace selector and passes `groupTransferLocationsApiMethod` prop', () => {
    createComponent();

    expect(findTransferLocations().exists()).toBe(true);

    findTransferLocations().props('groupTransferLocationsApiMethod')();
    expect(getTransferLocations).toHaveBeenCalled();
  });

  it('renders the confirm button', () => {
    createComponent();

    expect(findConfirmDanger().exists()).toBe(true);
  });

  describe('showUserTransferLocations prop', () => {
    it('passes `true` to TransferLocations by default', () => {
      createComponent();

      expect(findTransferLocations().props('showUserTransferLocations')).toBe(true);
    });

    it('passes `false` to TransferLocations when showUserTransferLocations is false', () => {
      createComponent({ showUserTransferLocations: false });

      expect(findTransferLocations().props('showUserTransferLocations')).toBe(false);
    });
  });

  it('disables the confirm button by default', () => {
    createComponent();

    expect(findConfirmDanger().attributes('disabled')).toBeDefined();
  });

  describe('with a selected namespace', () => {
    const [selectedItem] = transferLocationsResponsePage1;

    const selectNamespace = () => findTransferLocations().vm.$emit('input', selectedItem);

    it('sets `value` prop on `TransferLocations` component', async () => {
      createComponent();
      selectNamespace();
      await nextTick();

      expect(findTransferLocations().props('value')).toEqual(selectedItem);
    });

    it('enables the confirm button', async () => {
      createComponent();
      selectNamespace();
      await nextTick();

      expect(findConfirmDanger().attributes('disabled')).toBeUndefined();
    });

    it('writes the selected namespace to the target hidden input', async () => {
      setHTMLFixture(`<input type="hidden" id="${targetHiddenInputId}" />`);
      createComponent();

      selectNamespace();
      await nextTick();

      expect(document.getElementById(targetHiddenInputId).value).toBe(String(selectedItem.id));

      resetHTMLFixture();
    });

    it('does not write anywhere when the target hidden input is not in the DOM', async () => {
      setHTMLFixture(`<input type="hidden" id="${targetHiddenInputId}" value="" />`);
      createComponent({ targetHiddenInputId: 'does-not-exist' });

      selectNamespace();
      await nextTick();

      expect(document.getElementById(targetHiddenInputId).value).toBe('');

      resetHTMLFixture();
    });
  });

  describe('when the confirm button is clicked', () => {
    let submitSpy;
    let modalEvent;

    beforeEach(() => {
      setHTMLFixture(`<form id="${targetFormId}"></form>`);
      submitSpy = jest.spyOn(HTMLFormElement.prototype, 'submit').mockImplementation();
      modalEvent = { preventDefault: jest.fn() };
    });

    afterEach(() => {
      resetHTMLFixture();
    });

    const confirm = () => findConfirmDanger().vm.$emit('confirm', modalEvent);

    it('keeps the modal open and submits the target form with the button loading', async () => {
      createComponent();

      confirm();
      await nextTick();

      expect(modalEvent.preventDefault).toHaveBeenCalled();
      expect(findConfirmDanger().props('confirmLoading')).toBe(true);
      expect(submitSpy).toHaveBeenCalled();
    });

    it('resets the loading state when the submit throws', async () => {
      submitSpy.mockImplementation(() => {
        throw new Error('submit failed');
      });
      createComponent();

      confirm();
      await nextTick();

      expect(findConfirmDanger().props('confirmLoading')).toBe(false);
    });

    it('does nothing when the target form is not in the DOM', async () => {
      createComponent({ targetFormId: 'does-not-exist' });

      confirm();
      await nextTick();

      expect(modalEvent.preventDefault).not.toHaveBeenCalled();
      expect(submitSpy).not.toHaveBeenCalled();
      expect(findConfirmDanger().props('confirmLoading')).toBe(false);
    });
  });
});

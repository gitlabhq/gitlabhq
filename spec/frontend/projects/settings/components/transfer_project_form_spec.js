import transferLocationsResponsePage1 from 'test_fixtures/api/projects/transfer_locations_page_1.json';
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

  const createComponent = () => {
    wrapper = shallowMountExtended(TransferProjectForm, {
      provide: {
        resourceId,
      },
      propsData: {
        confirmButtonText,
        confirmationPhrase,
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

  it('disables the confirm button by default', () => {
    createComponent();

    expect(findConfirmDanger().attributes('disabled')).toBeDefined();
  });

  describe('with a selected namespace', () => {
    const [selectedItem] = transferLocationsResponsePage1;

    beforeEach(() => {
      createComponent();
      findTransferLocations().vm.$emit('input', selectedItem);
    });

    it('sets `value` prop on `TransferLocations` component', () => {
      expect(findTransferLocations().props('value')).toEqual(selectedItem);
    });

    it('emits the `selectTransferLocation` event when a namespace is selected', () => {
      const args = [selectedItem.id];

      expect(wrapper.emitted('selectTransferLocation')).toEqual([args]);
    });

    it('enables the confirm button', () => {
      expect(findConfirmDanger().attributes('disabled')).toBeUndefined();
    });

    it('clicking the confirm button emits the `confirm` event', () => {
      findConfirmDanger().vm.$emit('confirm');

      expect(wrapper.emitted('confirm')).toBeDefined();
    });
  });
});

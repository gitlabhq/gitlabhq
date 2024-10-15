import { GlAlert, GlSprintf } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import TransferLocationsForm, { i18n } from '~/groups/components/transfer_group_form.vue';
import ConfirmDanger from '~/vue_shared/components/confirm_danger/confirm_danger.vue';
import TransferLocations from '~/groups_projects/components/transfer_locations.vue';
import { getGroupTransferLocations } from '~/api/groups_api';

jest.mock('~/api/groups_api', () => ({
  getGroupTransferLocations: jest.fn(),
}));

describe('Transfer group form', () => {
  let wrapper;

  const confirmButtonText = 'confirm';
  const confirmationPhrase = 'confirmation-phrase';
  const paidGroupHelpLink = 'some/fake/link';
  const groupNamespaces = [
    {
      id: 1,
      humanName: 'Group 1',
    },
    {
      id: 2,
      humanName: 'Group 2',
    },
  ];

  const defaultProps = {
    paidGroupHelpLink,
    isPaidGroup: false,
    confirmationPhrase,
    confirmButtonText,
  };

  const createComponent = (propsData = {}) => {
    wrapper = shallowMountExtended(TransferLocationsForm, {
      propsData: {
        ...defaultProps,
        ...propsData,
      },
      stubs: { GlSprintf },
    });
  };

  const findAlert = () => wrapper.findComponent(GlAlert);
  const findConfirmDanger = () => wrapper.findComponent(ConfirmDanger);
  const findTransferLocations = () => wrapper.findComponent(TransferLocations);
  const findHiddenInput = () => wrapper.find('[name="new_parent_group_id"]');

  describe('default', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders the transfer locations dropdown and passes correct props', () => {
      findTransferLocations().props('groupTransferLocationsApiMethod')();

      expect(getGroupTransferLocations).toHaveBeenCalled();
      expect(findTransferLocations().props()).toMatchObject({
        value: null,
        label: i18n.dropdownLabel,
        additionalDropdownItems: TransferLocationsForm.additionalDropdownItems,
      });
    });

    it('renders the hidden input field', () => {
      expect(findHiddenInput().exists()).toBe(true);
      expect(findHiddenInput().attributes('value')).toBeUndefined();
    });

    it('does not render the alert', () => {
      expect(findAlert().exists()).toBe(false);
    });

    it('renders the confirm danger component', () => {
      expect(findConfirmDanger().exists()).toBe(true);
    });

    it('sets the confirm danger properties', () => {
      expect(findConfirmDanger().props()).toMatchObject({
        disabled: true,
        buttonText: confirmButtonText,
        phrase: confirmationPhrase,
      });
    });
  });

  describe('with a selected group', () => {
    const [selectedItem] = groupNamespaces;

    beforeEach(() => {
      createComponent();
      findTransferLocations().vm.$emit('input', selectedItem);
    });

    it('sets `value` prop on `TransferLocations` component', () => {
      expect(findTransferLocations().props('value')).toEqual(selectedItem);
    });

    it('sets the confirm danger disabled property to false', () => {
      expect(findConfirmDanger().props()).toMatchObject({ disabled: false });
    });

    it('sets the hidden input field', () => {
      expect(findHiddenInput().exists()).toBe(true);
      expect(findHiddenInput().attributes('value')).toBe(String(selectedItem.id));
    });

    it('emits "confirm" event when the danger modal is confirmed', () => {
      expect(wrapper.emitted('confirm')).toBeUndefined();

      findConfirmDanger().vm.$emit('confirm');

      expect(wrapper.emitted('confirm')).toHaveLength(1);
    });
  });

  describe('isPaidGroup = true', () => {
    beforeEach(() => {
      createComponent({ isPaidGroup: true });
    });

    it('disables the transfer button', () => {
      expect(findConfirmDanger().props()).toMatchObject({ disabled: true });
    });

    it('hides the transfer locations dropdown', () => {
      expect(findTransferLocations().exists()).toBe(false);
    });
  });
});

import { GlModal, GlSprintf } from '@gitlab/ui';
import { nextTick } from 'vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import GroupsProjectsTransferModal from '~/groups_projects/components/transfer_modal.vue';
import TransferLocations from '~/groups_projects/components/transfer_locations.vue';

describe('GroupsProjectsTransferModal', () => {
  let wrapper;

  const resourceId = '1';
  const resourceFullPath = 'parent/test-group';

  const groupTransferLocationsApiMethod = jest.fn();
  const transferApiMethod = jest.fn();

  const defaultProvide = {
    resourceId,
    resourceFullPath,
  };

  const defaultPropsData = {
    visible: false,
    title: 'Transfer resource',
    groupTransferLocationsApiMethod,
    transferApiMethod,
  };

  const location = {
    id: 2,
    humanName: 'New Parent',
    newPath: 'new-parent/test-group',
  };

  const createComponent = (propsData = {}, provide = {}) => {
    wrapper = shallowMountExtended(GroupsProjectsTransferModal, {
      provide: {
        ...defaultProvide,
        ...provide,
      },
      propsData: {
        ...defaultPropsData,
        ...propsData,
      },
      stubs: {
        GlSprintf,
      },
    });
  };

  const findModal = () => wrapper.findComponent(GlModal);
  const findTransferLocations = () => wrapper.findComponent(TransferLocations);
  const findUrlChangeCheckbox = () => wrapper.findByTestId('url-change-confirmation');

  const selectLocation = async (value) => {
    findTransferLocations().vm.$emit('input', value);
    await nextTick();
  };

  const confirmTransfer = async () => {
    if (findUrlChangeCheckbox().exists()) {
      findUrlChangeCheckbox().vm.$emit('input', true);
      await nextTick();
    }
  };

  describe('default', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders modal with correct props', () => {
      expect(findModal().props()).toMatchObject({
        visible: false,
        title: 'Transfer resource',
      });
    });

    it('sets transfer button text and variant', () => {
      const primaryAction = findModal().props('actionPrimary');

      expect(primaryAction.text).toBe('Transfer');
      expect(primaryAction.attributes.variant).toBe('danger');
    });

    it('renders TransferLocations component with correct props', () => {
      expect(findTransferLocations().props()).toMatchObject({
        value: null,
        showUserTransferLocations: true,
        additionalDropdownItems: [],
        groupTransferLocationsApiMethod,
      });
    });

    describe('when no location is selected', () => {
      it('does not render checkboxes', () => {
        expect(findUrlChangeCheckbox().exists()).toBe(false);
      });

      it('disables transfer button', () => {
        const primaryAction = findModal().props('actionPrimary');

        expect(primaryAction.attributes.disabled).toBe(true);
      });
    });
  });

  describe('when location is selected', () => {
    beforeEach(async () => {
      createComponent();
      await selectLocation(location);
    });

    it('renders URL change confirmation checkbox with correct text', () => {
      const checkbox = findUrlChangeCheckbox();

      expect(checkbox.text()).toBe(
        `I understand that the URL will change from ${resourceFullPath} to ${location.newPath}`,
      );
    });

    describe('when URL change checkbox is not checked', () => {
      it('keeps transfer button disabled', () => {
        const primaryAction = findModal().props('actionPrimary');

        expect(primaryAction.attributes.disabled).toBe(true);
      });
    });
  });

  describe('when URL change confirmation is checked', () => {
    beforeEach(async () => {
      createComponent();
      await selectLocation(location);
      await confirmTransfer();
    });

    it('enables transfer button', () => {
      const primaryAction = findModal().props('actionPrimary');

      expect(primaryAction.attributes.disabled).toBe(false);
    });
  });

  describe('when transfer is submitted', () => {
    beforeEach(async () => {
      transferApiMethod.mockResolvedValue({});
      createComponent();
      await selectLocation(location);
      await confirmTransfer();
    });

    it('calls transfer API method with correct parameters', async () => {
      findModal().vm.$emit('primary', { preventDefault: jest.fn() });
      await nextTick();

      expect(transferApiMethod).toHaveBeenCalledWith(resourceId, location.id);
    });

    describe('when transfer is in progress', () => {
      it('shows loading state', async () => {
        transferApiMethod.mockImplementation(() => new Promise(() => {}));

        findModal().vm.$emit('primary', { preventDefault: jest.fn() });
        await nextTick();

        const primaryAction = findModal().props('actionPrimary');
        expect(primaryAction.attributes.loading).toBe(true);
      });
    });

    describe('when transfer succeeds', () => {
      beforeEach(async () => {
        findModal().vm.$emit('primary', { preventDefault: jest.fn() });
        await waitForPromises();
      });

      it('emits success and change events', () => {
        expect(wrapper.emitted('success')).toHaveLength(1);
        expect(wrapper.emitted('change')).toEqual([[false]]);
      });

      it('resets loading state', () => {
        const primaryAction = findModal().props('actionPrimary');
        expect(primaryAction.attributes.loading).toBe(false);
      });
    });

    describe('when transfer fails', () => {
      const errorMessage = 'Transfer failed';

      beforeEach(async () => {
        transferApiMethod.mockRejectedValue({
          response: { data: { message: errorMessage } },
        });
        findModal().vm.$emit('primary', { preventDefault: jest.fn() });
        await waitForPromises();
      });

      it('emits error event with message and closes modal', () => {
        expect(wrapper.emitted('error')).toEqual([[errorMessage]]);
        expect(wrapper.emitted('change')).toEqual([[false]]);
      });

      it('resets loading state', () => {
        const primaryAction = findModal().props('actionPrimary');
        expect(primaryAction.attributes.loading).toBe(false);
      });
    });
  });

  describe('when modal visibility changes', () => {
    it('emits change event', async () => {
      createComponent();

      findModal().vm.$emit('change', true);
      await nextTick();

      expect(wrapper.emitted('change')).toEqual([[true]]);
    });

    describe('when modal is closed', () => {
      beforeEach(async () => {
        createComponent({ visible: true });
        await selectLocation(location);
      });

      it('resets the form', async () => {
        findModal().vm.$emit('change', false);
        await nextTick();

        expect(findUrlChangeCheckbox().exists()).toBe(false);
        expect(findTransferLocations().props('value')).toBeNull();
      });
    });
  });

  describe('when showUserTransferLocations prop is false', () => {
    it('passes showUserTransferLocations to TransferLocations', () => {
      createComponent({ showUserTransferLocations: false });

      expect(findTransferLocations().props('showUserTransferLocations')).toBe(false);
    });
  });

  describe('when additionalDropdownItems prop is provided', () => {
    const additionalItems = [
      { id: -1, humanName: 'No parent' },
      { id: -2, humanName: 'Special option' },
    ];

    it('passes additionalDropdownItems to TransferLocations', () => {
      createComponent({ additionalDropdownItems: additionalItems });

      expect(findTransferLocations().props('additionalDropdownItems')).toEqual(additionalItems);
    });
  });

  describe('URL change checkbox visibility', () => {
    describe('when resourceFullPath is nullish', () => {
      it('hides URL change checkbox and enables transfer immediately', async () => {
        createComponent({}, { resourceFullPath: undefined });
        await selectLocation(location);

        expect(findUrlChangeCheckbox().exists()).toBe(false);

        const primaryAction = findModal().props('actionPrimary');
        expect(primaryAction.attributes.disabled).toBe(false);
      });
    });

    describe('when selected location newPath is nullish', () => {
      it('hides URL change checkbox and enables transfer immediately', async () => {
        createComponent();
        await selectLocation({ id: 2, humanName: 'New Parent' });

        expect(findUrlChangeCheckbox().exists()).toBe(false);

        const primaryAction = findModal().props('actionPrimary');
        expect(primaryAction.attributes.disabled).toBe(false);
      });
    });

    describe('when both resourceFullPath and selected location newPath are present', () => {
      it('shows URL change checkbox', async () => {
        createComponent();
        await selectLocation(location);

        expect(findUrlChangeCheckbox().exists()).toBe(true);
      });
    });
  });
});

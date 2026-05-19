import { GlAlert, GlLink, GlSprintf } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { createAlert } from '~/alert';
import TransferModal from '~/groups/components/transfer_modal.vue';
import GroupsProjectsTransferModal from '~/groups_projects/components/transfer_modal.vue';
import { getGroupTransferLocations, transferGroup } from '~/api/groups_api';

jest.mock('~/alert');
jest.mock('~/api/groups_api', () => ({
  getGroupTransferLocations: jest.fn(),
  transferGroup: jest.fn(),
}));

describe('TransferModal', () => {
  let wrapper;

  const mockGroup = {
    id: 1,
    name: 'Test Group',
    path: 'test-group',
    fullPath: 'test-group',
  };

  const defaultPropsData = {
    visible: false,
    group: mockGroup,
  };

  const createComponent = ({ props = {}, stubs = {} } = {}) => {
    wrapper = shallowMountExtended(TransferModal, {
      propsData: {
        ...defaultPropsData,
        ...props,
      },
      stubs,
    });
  };

  const findGroupsProjectsTransferModal = () => wrapper.findComponent(GroupsProjectsTransferModal);
  const findAlert = () => wrapper.findComponent(GlAlert);
  const findGlSprintf = () => wrapper.findComponent(GlSprintf);
  const findGlLink = () => wrapper.findComponent(GlLink);

  describe('default', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders GroupsProjectsTransferModal with correct props', () => {
      expect(findGroupsProjectsTransferModal().props()).toMatchObject({
        visible: defaultPropsData.visible,
        title: 'Transfer - Test Group',
        groupTransferLocationsApiMethod: getGroupTransferLocations,
        transferApiMethod: transferGroup,
        showUserTransferLocations: false,
        additionalDropdownItems: [
          {
            id: null,
            humanName: 'No parent group',
            newPath: 'test-group',
          },
        ],
      });
    });

    it('renders info alert with correct variant and title', () => {
      expect(findAlert().props('variant')).toBe('info');
      expect(findAlert().props('title')).toContain('Transferring this group will:');
    });

    it('renders all alert list items', () => {
      const listItems = findAlert().findAll('li');

      expect(listItems).toHaveLength(2);
      expect(listItems.at(0).text()).toBe('Change its repository URL paths.');
      expect(listItems.at(1).text()).toBe(
        'Change its visibility settings to match the new parent group.',
      );
    });

    it('renders transfer description message', () => {
      expect(findGlSprintf().attributes('message')).toBe(
        'Transfer this group and all its projects to a different parent group, or convert it to a top-level group. %{linkStart}How does group transfer work?%{linkEnd}',
      );
    });

    it('renders documentation link', () => {
      createComponent({ stubs: { GlSprintf } });

      expect(findGlLink().props('href')).toBe('/help/user/group/manage#transfer-a-group');
    });
  });

  describe('when modal emits change event', () => {
    it('emits change event', () => {
      createComponent();

      findGroupsProjectsTransferModal().vm.$emit('change', true);

      expect(wrapper.emitted('change')).toEqual([[true]]);
    });
  });

  describe('when modal emits success event', () => {
    it('emits success event', () => {
      createComponent();

      findGroupsProjectsTransferModal().vm.$emit('success');

      expect(wrapper.emitted('success')).toHaveLength(1);
    });
  });

  describe('when visible prop is true', () => {
    it('passes visible prop to GroupsProjectsTransferModal', () => {
      createComponent({ props: { visible: true } });

      expect(findGroupsProjectsTransferModal().props('visible')).toBe(true);
    });
  });

  describe('when modal emits error event', () => {
    it('shows alert with API error message', () => {
      createComponent();
      const errorMessage = 'Transfer failed';

      findGroupsProjectsTransferModal().vm.$emit('error', errorMessage);

      expect(createAlert).toHaveBeenCalledWith({
        message: errorMessage,
        captureError: true,
        error: errorMessage,
      });
    });

    it('shows default error message when no message provided', () => {
      createComponent();

      findGroupsProjectsTransferModal().vm.$emit('error', undefined);

      expect(createAlert).toHaveBeenCalledWith({
        message:
          'An error occurred while transferring the group. Please refresh the page to try again.',
        captureError: true,
        error: undefined,
      });
    });
  });
});

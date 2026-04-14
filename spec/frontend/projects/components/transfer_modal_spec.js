import { GlAlert, GlLink, GlSprintf } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { createAlert } from '~/alert';
import TransferModal from '~/projects/components/transfer_modal.vue';
import GroupsProjectsTransferModal from '~/groups_projects/components/transfer_modal.vue';
import { getTransferLocations, transferProject } from '~/api/projects_api';

jest.mock('~/alert');
jest.mock('~/api/projects_api', () => ({
  getTransferLocations: jest.fn(),
  transferProject: jest.fn(),
}));

describe('TransferModal', () => {
  let wrapper;

  const mockProject = {
    id: 1,
    name: 'Test Project',
    path: 'test-project',
    fullPath: 'namespace/test-project',
  };

  const defaultPropsData = {
    visible: false,
    project: mockProject,
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
        title: 'Transfer - Test Project',
        groupTransferLocationsApiMethod: getTransferLocations,
        transferApiMethod: transferProject,
        showUserTransferLocations: true,
      });
    });

    it('renders info alert with correct variant and title', () => {
      expect(findAlert().props('variant')).toBe('info');
      expect(findAlert().props('title')).toContain('Transferring this project will:');
    });

    it('renders all alert list items', () => {
      const listItems = findAlert().findAll('li');

      expect(listItems).toHaveLength(2);
      expect(listItems.at(0).text()).toBe('Change its repository URL path.');
      expect(listItems.at(1).text()).toBe(
        'Change its visibility settings to match the new namespace.',
      );
    });

    it('renders transfer description message', () => {
      expect(findGlSprintf().attributes('message')).toBe(
        'Transfer this project to a different namespace. %{linkStart}How does project transfer work?%{linkEnd}',
      );
    });

    it('renders documentation link', () => {
      createComponent({ stubs: { GlSprintf } });

      expect(findGlLink().props('href')).toBe(
        '/help/user/project/working_with_projects#transfer-a-project',
      );
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
    beforeEach(() => {
      createComponent();
    });

    it('shows alert with API error message', () => {
      const errorMessage = 'Transfer failed';

      findGroupsProjectsTransferModal().vm.$emit('error', errorMessage);

      expect(createAlert).toHaveBeenCalledWith({
        message: errorMessage,
        captureError: true,
      });
    });

    it('shows default error message when no message provided', () => {
      findGroupsProjectsTransferModal().vm.$emit('error', undefined);

      expect(createAlert).toHaveBeenCalledWith({
        message:
          'An error occurred while transferring the project. Please refresh the page to try again.',
        captureError: true,
      });
    });
  });
});

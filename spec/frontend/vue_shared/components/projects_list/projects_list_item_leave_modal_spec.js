import { GlModal } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import ProjectsListItemLeaveModal from '~/vue_shared/components/projects_list/projects_list_item_leave_modal.vue';
import waitForPromises from 'helpers/wait_for_promises';
import { renderLeaveSuccessToast } from '~/vue_shared/components/projects_list/utils';
import { createAlert } from '~/alert';
import { deleteProjectMember } from '~/api/projects_api';
import { projects } from './mock_data';

jest.mock('~/vue_shared/components/projects_list/utils', () => ({
  ...jest.requireActual('~/vue_shared/components/projects_list/utils'),
  renderLeaveSuccessToast: jest.fn(),
}));
jest.mock('~/alert');
jest.mock('~/api/projects_api');

describe('ProjectsListItemLeaveModal', () => {
  let wrapper;

  const userId = 1;
  const [project] = projects;
  const defaultProps = {
    project,
  };

  const createComponent = ({ props = {} } = {}) => {
    window.gon.current_user_id = userId;
    wrapper = shallowMountExtended(ProjectsListItemLeaveModal, {
      propsData: { ...defaultProps, ...props },
    });
  };

  const findGlModal = () => wrapper.findComponent(GlModal);
  const firePrimaryEvent = () => findGlModal().vm.$emit('primary', { preventDefault: jest.fn() });

  beforeEach(createComponent);

  it('renders GlModal with correct props', () => {
    expect(findGlModal().props()).toMatchObject({
      visible: false,
      modalId: expect.stringContaining('projects-list-item-leave-modal-'),
      title: `Are you sure you want to leave "${project.nameWithNamespace}"?`,
      actionPrimary: {
        text: 'Leave project',
        attributes: {
          variant: 'danger',
        },
      },
      actionCancel: {
        text: 'Cancel',
      },
    });
  });

  it('renders body', () => {
    expect(findGlModal().text()).toContain('When you leave this project:');
    expect(findGlModal().text()).toContain(
      'You are no longer a project member and cannot contribute.',
    );
    expect(findGlModal().text()).toContain(
      'All the issues and merge requests that were assigned to you are unassigned.',
    );
  });

  describe('when leave is confirmed', () => {
    describe('when API call is successful', () => {
      it('calls deleteProjectMember, properly sets loading state, and emits confirm event', async () => {
        deleteProjectMember.mockResolvedValueOnce();

        await firePrimaryEvent();

        expect(deleteProjectMember).toHaveBeenCalledWith(project.id, userId);
        expect(findGlModal().props('actionPrimary').attributes.loading).toEqual(true);

        await waitForPromises();

        expect(findGlModal().props('actionPrimary').attributes.loading).toEqual(false);
        expect(wrapper.emitted('success')).toEqual([[]]);
        expect(renderLeaveSuccessToast).toHaveBeenCalledWith(project);
        expect(createAlert).not.toHaveBeenCalled();
      });
    });

    describe('when API call is not successful', () => {
      const error = new Error();

      it('calls deleteProjectMember, properly sets loading state, and shows error alert', async () => {
        deleteProjectMember.mockRejectedValue(error);

        await firePrimaryEvent();

        expect(deleteProjectMember).toHaveBeenCalledWith(project.id, userId);
        expect(findGlModal().props('actionPrimary').attributes.loading).toEqual(true);

        await waitForPromises();

        expect(findGlModal().props('actionPrimary').attributes.loading).toEqual(false);
        expect(wrapper.emitted('success')).toBeUndefined();
        expect(renderLeaveSuccessToast).not.toHaveBeenCalled();
        expect(createAlert).toHaveBeenCalledWith({
          message:
            'An error occurred while leaving the project. Please refresh the page to try again.',
          error,
          captureError: true,
        });
      });
    });
  });

  describe('when change is fired', () => {
    beforeEach(() => {
      findGlModal().vm.$emit('change', false);
    });

    it('emits change event', () => {
      expect(wrapper.emitted('change')).toMatchObject([[]]);
    });
  });
});

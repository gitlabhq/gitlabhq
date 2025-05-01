import { GlModal } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import GroupListItemLeaveModal from '~/vue_shared/components/groups_list/group_list_item_leave_modal.vue';
import { groups } from 'jest/vue_shared/components/groups_list/mock_data';
import waitForPromises from 'helpers/wait_for_promises';
import { renderLeaveSuccessToast } from '~/vue_shared/components/groups_list/utils';
import { createAlert } from '~/alert';
import { deleteGroupMember } from '~/api/groups_api';

jest.mock('~/vue_shared/components/groups_list/utils', () => ({
  ...jest.requireActual('~/vue_shared/components/groups_list/utils'),
  renderLeaveSuccessToast: jest.fn(),
}));
jest.mock('~/alert');
jest.mock('~/api/groups_api');

describe('GroupListItemLeaveModal', () => {
  let wrapper;

  const userId = 1;
  const [group] = groups;
  const defaultProps = {
    modalId: '123',
    group,
  };

  const createComponent = ({ props = {} } = {}) => {
    window.gon.current_user_id = userId;
    wrapper = shallowMountExtended(GroupListItemLeaveModal, {
      propsData: { ...defaultProps, ...props },
    });
  };

  const findGlModal = () => wrapper.findComponent(GlModal);
  const firePrimaryEvent = () => findGlModal().vm.$emit('primary', { preventDefault: jest.fn() });

  beforeEach(createComponent);

  it('renders GlModal with correct props', () => {
    expect(findGlModal().props()).toMatchObject({
      visible: false,
      modalId: defaultProps.modalId,
      title: `Are you sure you want to leave "${group.fullName}"?`,
      actionPrimary: {
        text: 'Leave group',
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
    expect(findGlModal().text()).toContain('When you leave this group:');
    expect(findGlModal().text()).toContain('You lose access to all projects within this group');
    expect(findGlModal().text()).toContain(
      'Your assigned issues and merge requests remain, but you cannot view or modify them',
    );
    expect(findGlModal().text()).toContain('You need an invitation to rejoin');
  });

  describe('when leave is confirmed', () => {
    describe('when API call is successful', () => {
      it('calls deleteGroupMember, properly sets loading state, and emits confirm event', async () => {
        deleteGroupMember.mockResolvedValueOnce();

        await firePrimaryEvent();

        expect(deleteGroupMember).toHaveBeenCalledWith(group.id, userId);
        expect(findGlModal().props('actionPrimary').attributes.loading).toEqual(true);

        await waitForPromises();

        expect(findGlModal().props('actionPrimary').attributes.loading).toEqual(false);
        expect(wrapper.emitted('success')).toEqual([[]]);
        expect(renderLeaveSuccessToast).toHaveBeenCalledWith(group);
        expect(createAlert).not.toHaveBeenCalled();
      });
    });

    describe('when API call is not successful', () => {
      const error = new Error();

      it('calls deleteGroupMember, properly sets loading state, and shows error alert', async () => {
        deleteGroupMember.mockRejectedValue(error);

        await firePrimaryEvent();

        expect(deleteGroupMember).toHaveBeenCalledWith(group.id, userId);
        expect(findGlModal().props('actionPrimary').attributes.loading).toEqual(true);

        await waitForPromises();

        expect(findGlModal().props('actionPrimary').attributes.loading).toEqual(false);
        expect(wrapper.emitted('success')).toBeUndefined();
        expect(renderLeaveSuccessToast).not.toHaveBeenCalled();
        expect(createAlert).toHaveBeenCalledWith({
          message:
            'An error occurred while leaving the group. Please refresh the page to try again.',
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

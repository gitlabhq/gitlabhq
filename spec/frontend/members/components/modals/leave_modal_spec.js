import { GlModal, GlForm } from '@gitlab/ui';
import { cloneDeep } from 'lodash';
import Vue, { nextTick } from 'vue';
// eslint-disable-next-line no-restricted-imports
import Vuex from 'vuex';
import { mountExtended, extendedWrapper } from 'helpers/vue_test_utils_helper';
import LeaveModal from '~/members/components/modals/leave_modal.vue';
import {
  LEAVE_MODAL_ID,
  MEMBERS_TAB_TYPES,
  MEMBER_MODEL_TYPE_PROJECT_MEMBER,
} from '~/members/constants';
import UserDeletionObstaclesList from '~/vue_shared/components/user_deletion_obstacles/user_deletion_obstacles_list.vue';
import { parseUserDeletionObstacles } from '~/vue_shared/components/user_deletion_obstacles/utils';
import { member } from '../../mock_data';

jest.mock('~/lib/utils/csrf', () => ({ token: 'mock-csrf-token' }));

Vue.use(Vuex);

describe('LeaveModal', () => {
  let wrapper;

  const createStore = (state = {}) => {
    return new Vuex.Store({
      modules: {
        [MEMBERS_TAB_TYPES.user]: {
          namespaced: true,
          state: {
            memberPath: '/groups/foo-bar/-/group_members/:id',
            ...state,
          },
        },
      },
    });
  };

  const createComponent = async (propsData = {}, state) => {
    wrapper = mountExtended(LeaveModal, {
      store: createStore(state),
      provide: {
        namespace: MEMBERS_TAB_TYPES.user,
      },
      propsData: {
        member,
        permissions: {
          canRemove: true,
        },
        ...propsData,
      },
      attrs: {
        static: true,
        visible: true,
      },
    });

    await nextTick();
  };

  const findModal = () => extendedWrapper(wrapper.findComponent(GlModal));
  const findForm = () => findModal().findComponent(GlForm);
  const findUserDeletionObstaclesList = () => findModal().findComponent(UserDeletionObstaclesList);

  it('sets modal ID', async () => {
    await createComponent();

    expect(findModal().props('modalId')).toBe(LEAVE_MODAL_ID);
  });

  describe('when leave is allowed', () => {
    it('displays modal title', async () => {
      await createComponent();

      expect(findModal().findByText(`Leave "${member.source.fullName}"`).exists()).toBe(true);
    });

    it('displays modal body', async () => {
      await createComponent();

      expect(
        findModal()
          .findByText(`Are you sure you want to leave "${member.source.fullName}"?`)
          .exists(),
      ).toBe(true);
    });
  });

  describe('when leave is blocked by last owner', () => {
    const permissions = {
      canRemove: false,
      canRemoveBlockedByLastOwner: true,
    };

    it('does not show primary action button', async () => {
      await createComponent({
        permissions,
      });

      expect(findModal().props('actionPrimary')).toBe(null);
    });

    it('displays modal title', async () => {
      await createComponent({
        permissions,
      });

      expect(findModal().findByText(`Cannot leave "${member.source.fullName}"`).exists()).toBe(
        true,
      );
    });

    describe('when member model type is `GroupMember`', () => {
      it('displays modal body', async () => {
        await createComponent({
          permissions,
        });

        expect(
          findModal().findByText(LeaveModal.i18n.preventedBodyGroupMemberModelType).exists(),
        ).toBe(true);
      });
    });

    describe('when member model type is `ProjectMember`', () => {
      it('displays modal body', async () => {
        await createComponent({
          member: {
            ...member,
            type: MEMBER_MODEL_TYPE_PROJECT_MEMBER,
          },
          permissions,
        });

        expect(
          findModal().findByText(LeaveModal.i18n.preventedBodyProjectMemberModelType).exists(),
        ).toBe(true);
      });
    });
  });

  it('displays form with correct action and inputs', async () => {
    await createComponent();

    const form = findForm();

    expect(form.attributes('action')).toBe('/groups/foo-bar/-/group_members/leave');
    expect(form.find('input[name="_method"]').attributes('value')).toBe('delete');
    expect(form.find('input[name="authenticity_token"]').attributes('value')).toBe(
      'mock-csrf-token',
    );
  });

  describe('User deletion obstacles list', () => {
    it("displays obstacles list when member's user is part of on-call management", async () => {
      await createComponent();

      const obstaclesList = findUserDeletionObstaclesList();
      expect(obstaclesList.exists()).toBe(true);
      expect(obstaclesList.props()).toMatchObject({
        isCurrentUser: true,
        obstacles: parseUserDeletionObstacles(member.user),
      });
    });

    it("does NOT display obstacles list when member's user is NOT a part of on-call management", async () => {
      wrapper.destroy();

      const memberWithoutOncall = cloneDeep(member);
      delete memberWithoutOncall.user.oncallSchedules;
      delete memberWithoutOncall.user.escalationPolicies;

      await createComponent({ member: memberWithoutOncall });

      expect(findUserDeletionObstaclesList().exists()).toBe(false);
    });
  });

  it('submits the form when "Leave" button is clicked', async () => {
    await createComponent();

    const submitSpy = jest.spyOn(findForm().element, 'submit');

    findModal().findByText('Leave').trigger('click');

    expect(submitSpy).toHaveBeenCalled();

    submitSpy.mockRestore();
  });
});

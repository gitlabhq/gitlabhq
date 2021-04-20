import { GlModal } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import OncallSchedulesList from '~/vue_shared/components/oncall_schedules_list.vue';
import RemoveMemberModal from '~/vue_shared/components/remove_member_modal.vue';

const mockSchedules = JSON.stringify({
  schedules: [
    {
      id: 1,
      name: 'Schedule 1',
    },
  ],
  name: 'User1',
});

describe('RemoveMemberModal', () => {
  const memberPath = '/gitlab-org/gitlab-test/-/project_members/90';
  let wrapper;

  const findForm = () => wrapper.find({ ref: 'form' });
  const findGlModal = () => wrapper.findComponent(GlModal);
  const findOnCallSchedulesList = () => wrapper.findComponent(OncallSchedulesList);

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe.each`
    state                          | memberType         | isAccessRequest | isInvite   | actionText               | removeSubMembershipsCheckboxExpected | unassignIssuablesCheckboxExpected | message                                                                                                           | onCallSchedules
    ${'removing a group member'}   | ${'GroupMember'}   | ${false}        | ${'false'} | ${'Remove member'}       | ${true}                              | ${true}                           | ${'Are you sure you want to remove Jane Doe from the Gitlab Org / Gitlab Test project?'}                          | ${`{}`}
    ${'removing a project member'} | ${'ProjectMember'} | ${false}        | ${'false'} | ${'Remove member'}       | ${false}                             | ${true}                           | ${'Are you sure you want to remove Jane Doe from the Gitlab Org / Gitlab Test project?'}                          | ${mockSchedules}
    ${'denying an access request'} | ${'ProjectMember'} | ${true}         | ${'false'} | ${'Deny access request'} | ${false}                             | ${false}                          | ${"Are you sure you want to deny Jane Doe's request to join the Gitlab Org / Gitlab Test project?"}               | ${`{}`}
    ${'revoking invite'}           | ${'ProjectMember'} | ${false}        | ${'true'}  | ${'Revoke invite'}       | ${false}                             | ${false}                          | ${'Are you sure you want to revoke the invitation for foo@bar.com to join the Gitlab Org / Gitlab Test project?'} | ${mockSchedules}
  `(
    'when $state',
    ({
      actionText,
      memberType,
      isAccessRequest,
      isInvite,
      message,
      removeSubMembershipsCheckboxExpected,
      unassignIssuablesCheckboxExpected,
      onCallSchedules,
    }) => {
      beforeEach(() => {
        wrapper = shallowMount(RemoveMemberModal, {
          data() {
            return {
              modalData: {
                isAccessRequest,
                isInvite,
                message,
                memberPath,
                memberType,
                onCallSchedules,
              },
            };
          },
        });
      });

      const parsedSchedules = JSON.parse(onCallSchedules);
      const isPartOfOncallSchedules = Boolean(isAccessRequest && parsedSchedules.schedules?.length);

      it(`has the title ${actionText}`, () => {
        expect(findGlModal().attributes('title')).toBe(actionText);
      });

      it('contains a form action', () => {
        expect(findForm().attributes('action')).toBe(memberPath);
      });

      it('displays a message to the user', () => {
        expect(wrapper.find('[data-testid=modal-message]').text()).toBe(message);
      });

      it(`shows ${
        removeSubMembershipsCheckboxExpected ? 'a' : 'no'
      } checkbox to remove direct memberships of subgroups/projects`, () => {
        expect(wrapper.find('[name=remove_sub_memberships]').exists()).toBe(
          removeSubMembershipsCheckboxExpected,
        );
      });

      it(`shows ${
        unassignIssuablesCheckboxExpected ? 'a' : 'no'
      } checkbox to allow removal from related issues and MRs`, () => {
        expect(wrapper.find('[name=unassign_issuables]').exists()).toBe(
          unassignIssuablesCheckboxExpected,
        );
      });

      it(`shows ${isPartOfOncallSchedules ? 'all' : 'no'} related on-call schedules`, () => {
        expect(findOnCallSchedulesList().exists()).toBe(isPartOfOncallSchedules);
      });

      it('submits the form when the modal is submitted', () => {
        const spy = jest.spyOn(findForm().element, 'submit');

        findGlModal().vm.$emit('primary');

        expect(spy).toHaveBeenCalled();

        spy.mockRestore();
      });
    },
  );
});

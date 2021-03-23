import { GlModal } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import RemoveMemberModal from '~/vue_shared/components/remove_member_modal.vue';

describe('RemoveMemberModal', () => {
  const memberPath = '/gitlab-org/gitlab-test/-/project_members/90';
  let wrapper;

  const findForm = () => wrapper.find({ ref: 'form' });
  const findGlModal = () => wrapper.find(GlModal);

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe.each`
    state                          | memberType         | isAccessRequest | actionText               | removeSubMembershipsCheckboxExpected | unassignIssuablesCheckboxExpected | message
    ${'removing a group member'}   | ${'GroupMember'}   | ${'false'}      | ${'Remove member'}       | ${true}                              | ${true}                           | ${'Are you sure you want to remove Jane Doe from the Gitlab Org / Gitlab Test project?'}
    ${'removing a project member'} | ${'ProjectMember'} | ${'false'}      | ${'Remove member'}       | ${false}                             | ${true}                           | ${'Are you sure you want to remove Jane Doe from the Gitlab Org / Gitlab Test project?'}
    ${'denying an access request'} | ${'ProjectMember'} | ${'true'}       | ${'Deny access request'} | ${false}                             | ${false}                          | ${"Are you sure you want to deny Jane Doe's request to join the Gitlab Org / Gitlab Test project?"}
  `(
    'when $state',
    ({
      actionText,
      memberType,
      isAccessRequest,
      message,
      removeSubMembershipsCheckboxExpected,
      unassignIssuablesCheckboxExpected,
    }) => {
      beforeEach(() => {
        wrapper = shallowMount(RemoveMemberModal, {
          data() {
            return {
              modalData: {
                isAccessRequest,
                message,
                memberPath,
                memberType,
              },
            };
          },
        });
      });

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

      it('submits the form when the modal is submitted', () => {
        const spy = jest.spyOn(findForm().element, 'submit');

        findGlModal().vm.$emit('primary');

        expect(spy).toHaveBeenCalled();

        spy.mockRestore();
      });
    },
  );
});

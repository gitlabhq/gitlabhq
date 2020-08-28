import { GlFormCheckbox, GlModal } from '@gitlab/ui';
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
    state                          | isAccessRequest | actionText               | checkboxTestDescription                                            | checkboxExpected | message
    ${'removing a member'}         | ${'false'}      | ${'Remove member'}       | ${'shows a checkbox to allow removal from related issues and MRs'} | ${true}          | ${'Are you sure you want to remove Jane Doe from the Gitlab Org / Gitlab Test project?'}
    ${'denying an access request'} | ${'true'}       | ${'Deny access request'} | ${'does not show a checkbox'}                                      | ${false}         | ${"Are you sure you want to deny Jane Doe's request to join the Gitlab Org / Gitlab Test project?"}
  `(
    'when $state',
    ({ actionText, isAccessRequest, message, checkboxTestDescription, checkboxExpected }) => {
      beforeEach(() => {
        wrapper = shallowMount(RemoveMemberModal, {
          data() {
            return {
              modalData: {
                isAccessRequest,
                message,
                memberPath,
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

      it(`${checkboxTestDescription}`, () => {
        expect(wrapper.find(GlFormCheckbox).exists()).toBe(checkboxExpected);
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

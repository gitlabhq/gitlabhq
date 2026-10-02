import { shallowMount } from '@vue/test-utils';
import ResyncLdap from '~/admin/users/components/actions/resync_ldap.vue';
import { I18N_USER_ACTIONS } from '~/admin/users/constants';
import eventHub, { EVENT_OPEN_CONFIRM_MODAL } from '~/vue_shared/components/confirm_modal_eventhub';

jest.mock('~/vue_shared/components/confirm_modal_eventhub', () => ({
  ...jest.requireActual('~/vue_shared/components/confirm_modal_eventhub'),
  __esModule: true,
  default: {
    $emit: jest.fn(),
  },
}));

describe('ResyncLdap component', () => {
  let wrapper;

  const defaultPropsData = {
    username: 'test_user',
    path: '/admin/users/test_user/unblock',
  };

  const createComponent = (props = {}) => {
    wrapper = shallowMount(ResyncLdap, {
      propsData: {
        ...defaultPropsData,
        ...props,
      },
    });
  };

  describe('onClick method', () => {
    beforeEach(() => {
      jest.spyOn(eventHub, '$emit');
      createComponent();
      wrapper.vm.onClick();
    });

    it('emits EVENT_OPEN_CONFIRM_MODAL with the resync path and PUT method', () => {
      expect(eventHub.$emit).toHaveBeenCalledWith(
        EVENT_OPEN_CONFIRM_MODAL,
        expect.objectContaining({
          path: defaultPropsData.path,
          method: 'put',
        }),
      );
    });

    it('emits a confirmation modal with the username in the title', () => {
      expect(eventHub.$emit).toHaveBeenCalledWith(
        EVENT_OPEN_CONFIRM_MODAL,
        expect.objectContaining({
          modalAttributes: expect.objectContaining({
            title: `Resync ${defaultPropsData.username} with LDAP?`,
          }),
        }),
      );
    });

    it('emits a confirmation modal with the resync action as the primary button', () => {
      expect(eventHub.$emit).toHaveBeenCalledWith(
        EVENT_OPEN_CONFIRM_MODAL,
        expect.objectContaining({
          modalAttributes: expect.objectContaining({
            actionPrimary: expect.objectContaining({
              text: I18N_USER_ACTIONS.resyncLdap,
              attributes: { variant: 'confirm' },
            }),
          }),
        }),
      );
    });
  });
});

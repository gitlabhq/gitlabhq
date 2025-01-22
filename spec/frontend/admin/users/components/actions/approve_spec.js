import { shallowMount } from '@vue/test-utils';
import Approve from '~/admin/users/components/actions/approve.vue';
import eventHub, { EVENT_OPEN_CONFIRM_MODAL } from '~/vue_shared/components/confirm_modal_eventhub';

jest.mock('~/vue_shared/components/confirm_modal_eventhub', () => ({
  ...jest.requireActual('~/vue_shared/components/confirm_modal_eventhub'),
  __esModule: true,
  default: {
    $emit: jest.fn(),
  },
}));

describe('Approve component', () => {
  let wrapper;

  const createComponent = (props = {}, isAtSeatsLimit = false) => {
    wrapper = shallowMount(Approve, {
      propsData: {
        username: 'test_user',
        path: '/admin/users/test_user/approve',
        ...props,
      },
      provide: {
        isAtSeatsLimit,
      },
    });
  };

  describe('onClick method', () => {
    beforeEach(() => {
      jest.spyOn(eventHub, '$emit');
    });

    it('emits EVENT_OPEN_CONFIRM_MODAL with correct props when not at users limit', () => {
      createComponent();
      wrapper.vm.onClick();

      expect(eventHub.$emit).toHaveBeenCalledWith(
        EVENT_OPEN_CONFIRM_MODAL,
        expect.objectContaining({
          path: '/admin/users/test_user/approve',
          modalAttributes: expect.objectContaining({
            errorAlertMessage: null,
            actionPrimary: expect.objectContaining({
              attributes: expect.objectContaining({
                disabled: false,
              }),
            }),
          }),
        }),
      );
    });

    it('emits EVENT_OPEN_CONFIRM_MODAL with disabled button when at users limit', () => {
      createComponent({}, true);
      wrapper.vm.onClick();

      expect(eventHub.$emit).toHaveBeenCalledWith(
        EVENT_OPEN_CONFIRM_MODAL,
        expect.objectContaining({
          modalAttributes: expect.objectContaining({
            errorAlertMessage:
              'There are no more seats left in your subscription. New users cannot be approved for this instance.',
            actionPrimary: expect.objectContaining({
              attributes: expect.objectContaining({
                disabled: true,
              }),
            }),
          }),
        }),
      );
    });
  });
});

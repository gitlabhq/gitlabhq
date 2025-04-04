import { GlModal } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import BeforeSubmitApproveUsersModal from '~/pages/admin/application_settings/general/components/before_submit_approve_users_modal.vue';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import { stubComponent } from 'helpers/stub_component';

jest.mock('~/sentry/sentry_browser_wrapper');

describe('BeforeSubmitApproveUsersModal', () => {
  /** @type {import('helpers/vue_test_utils_helper').ExtendedWrapper} */
  let wrapper;
  let beforeSubmitHook;
  let beforeSubmitHookContexts = {};

  const modalId = 'before-submit-modal-id';

  const findModal = () => wrapper.findComponent(GlModal);
  const verifyApproveUsers = () => beforeSubmitHook.mock.calls[0][0]();
  const modalStub = { show: jest.fn(), hide: jest.fn() };
  const GlModalStub = stubComponent(GlModal, { methods: modalStub });

  const createComponent = ({ provide = {} } = {}) => {
    beforeSubmitHook = jest.fn();

    wrapper = shallowMountExtended(BeforeSubmitApproveUsersModal, {
      propsData: { id: modalId },
      provide: {
        beforeSubmitHook,
        beforeSubmitHookContexts,
        pendingUserCount: 10,
        ...provide,
      },
      stubs: {
        GlModal: GlModalStub,
      },
    });
  };

  describe('with should prevent submit', () => {
    beforeEach(() => {
      beforeSubmitHookContexts = { [modalId]: { shouldPreventSubmit: () => true } };
      createComponent();
      verifyApproveUsers();
    });

    it('shows the modal', () => {
      expect(modalStub.show).toHaveBeenCalled();
    });

    it('shows a title', () => {
      expect(findModal().props('title')).toBe('Change setting and approve pending users?');
    });

    it('shows a text', () => {
      expect(wrapper.text()).toBe(
        'By changing this setting, you can also automatically approve 10 users who are pending approval.',
      );
    });

    it('shows a confirm button', () => {
      expect(findModal().props('actionPrimary').text).toBe('Proceed and approve 10 users');
    });

    it('shows a secondary button', () => {
      expect(findModal().props('actionSecondary').text).toBe('Proceed without auto-approval');
    });

    it('shows a cancel button', () => {
      expect(findModal().props('actionCancel').text).toBe('Cancel');
    });

    it('registers the hook', () => {
      expect(beforeSubmitHook).toHaveBeenCalledWith(expect.any(Function));
    });

    it.each(['hide', 'primary', 'secondary'])('emits %s event', (event) => {
      findModal().vm.$emit(event);

      expect(wrapper.emitted(event)).toHaveLength(1);
    });
  });

  describe('when the before submit hook has no reference ID', () => {
    it('does not show the modal', () => {
      beforeSubmitHookContexts = {};
      createComponent();
      verifyApproveUsers();

      expect(modalStub.show).not.toHaveBeenCalled();
    });
  });

  describe('with should prevent submit to false', () => {
    it('does not show the modal', () => {
      beforeSubmitHookContexts = { [modalId]: { shouldPreventSubmit: () => false } };
      createComponent();
      verifyApproveUsers();

      expect(modalStub.show).not.toHaveBeenCalled();
    });
  });

  describe('with should prevent submit not provided', () => {
    it('does not show the modal', () => {
      beforeSubmitHookContexts = { [modalId]: {} };
      createComponent();
      verifyApproveUsers();

      expect(modalStub.show).not.toHaveBeenCalled();
    });
  });

  describe('with should prevent raising an error', () => {
    it('captures the error with Sentry', () => {
      const error = new Error('This is an error');
      beforeSubmitHookContexts = {
        [modalId]: {
          shouldPreventSubmit: () => {
            throw error;
          },
        },
      };
      createComponent();
      verifyApproveUsers();

      expect(Sentry.captureException).toHaveBeenCalledWith(error, {
        tags: { vue_component: 'before_submit_approve_users_modal' },
      });
    });
  });
});

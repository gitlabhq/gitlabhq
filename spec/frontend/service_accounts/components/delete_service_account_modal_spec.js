import { GlModal, GlFormFields, GlFormInput } from '@gitlab/ui';
import { createTestingPinia } from '@pinia/testing';
import Vue, { nextTick } from 'vue';
import { PiniaVuePlugin } from 'pinia';

import DeleteServiceAccountModal from '~/service_accounts/components/delete_service_account_modal.vue';
import { useServiceAccounts } from '~/service_accounts/stores/service_accounts';
import { stubComponent } from 'helpers/stub_component';
import { mountExtended } from 'helpers/vue_test_utils_helper';

Vue.use(PiniaVuePlugin);

describe('DeleteServiceAccountModal', () => {
  let wrapper;

  const pinia = createTestingPinia();
  const store = useServiceAccounts();

  const name = 'My Service Account';

  const createComponent = (props = { deleteType: 'soft' }) => {
    wrapper = mountExtended(DeleteServiceAccountModal, {
      pinia,
      propsData: {
        name,
        ...props,
      },
      stubs: {
        GlModal: stubComponent(GlModal),
      },
    });
  };

  const findModal = () => wrapper.findComponent(GlModal);
  const findForm = () => wrapper.findComponent(GlFormFields);
  const findCancelButton = () => wrapper.findByTestId('cancel-button');
  const findSubmitButton = () => wrapper.find('button[type=submit]');
  const findInput = () => wrapper.findComponent(GlFormInput);

  describe('modal', () => {
    it('emits cancel event when hidden', () => {
      createComponent();
      expect(wrapper.emitted('cancel')).toBeUndefined();
      findModal().vm.$emit('hide');

      expect(wrapper.emitted('cancel')).toBeDefined();
    });

    it('emits cancel event when closed', () => {
      createComponent();
      expect(wrapper.emitted('cancel')).toBeUndefined();
      findModal().vm.$emit('close');

      expect(wrapper.emitted('cancel')).toBeDefined();
    });

    describe('when deleteType prop is soft', () => {
      beforeEach(() => {
        createComponent();
      });

      it('renders correct modal title', () => {
        expect(findModal().props('title')).toBe("Delete User 'My Service Account'?");
      });

      it('renders correct modal body', () => {
        expect(findModal().text()).toContain(
          'You are about to permanently delete the user My Service Account. Issues, merge requests, and groups linked to them will be transferred to a system-wide "Ghost-user". Once you Delete user, it cannot be undone or recovered.',
        );
      });
    });

    describe('when deleteType prop is hard', () => {
      beforeEach(() => {
        createComponent({ deleteType: 'hard' });
      });

      it('renders correct modal title', () => {
        expect(findModal().props('title')).toBe(
          "Delete User 'My Service Account' and contributions?",
        );
      });

      it('renders correct modal body', () => {
        expect(findModal().text()).toContain(
          'You are about to permanently delete the user My Service Account. This will delete all issues, merge requests, groups, and projects linked to them. After you Delete user, you cannot undo this action or recover the data.',
        );
      });
    });
  });

  describe('form', () => {
    beforeEach(() => {
      createComponent();
    });

    it('contains correct fields', () => {
      expect(findForm().props('fields')).toMatchObject({
        name: {
          inputAttrs: { autocomplete: 'off', autofocus: true },
          validators: [expect.any(Function)],
        },
      });
    });

    it('contains correct label', () => {
      expect(findForm().text()).toContain('To confirm, type My Service Account');
    });

    describe('cancel button', () => {
      it('contains correct text', () => {
        expect(findCancelButton().text()).toBe('Cancel');
      });

      it('emits cancel event when clicked', () => {
        expect(wrapper.emitted('cancel')).toBeUndefined();
        findCancelButton().trigger('click');

        expect(wrapper.emitted('cancel')).toBeDefined();
      });
    });

    describe('submit button', () => {
      describe('when deleteType prop is soft', () => {
        it('contains correct text', () => {
          expect(findSubmitButton().text()).toBe('Delete user');
        });
      });

      describe('when deleteType prop is hard', () => {
        it('contains correct text', () => {
          createComponent({ deleteType: 'hard' });

          expect(findSubmitButton().text()).toBe('Delete user and contributions');
        });
      });

      it('shows as loading when busy', async () => {
        expect(findSubmitButton().props('loading')).toBe(false);
        store.busy = true;
        await nextTick();

        expect(findSubmitButton().props('loading')).toBe(true);
      });

      it('does not emit submit event when input field is empty', () => {
        expect(wrapper.emitted('submit')).toBeUndefined();
        findSubmitButton().trigger('click');

        expect(wrapper.emitted('submit')).toBeUndefined();
      });

      it('emits submit event when input field is completed property', () => {
        expect(wrapper.emitted('submit')).toBeUndefined();
        findInput().setValue(name);
        findForm().vm.$emit('submit');

        expect(wrapper.emitted('submit')).toBeDefined();
      });
    });
  });
});

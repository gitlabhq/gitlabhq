import { GlModal, GlFormFields, GlAlert } from '@gitlab/ui';
import { createTestingPinia } from '@pinia/testing';
import Vue, { nextTick } from 'vue';
import { PiniaVuePlugin } from 'pinia';

import CreateEditServiceAccountModal from '~/service_accounts/components/create_edit_service_account_modal.vue';
import { useServiceAccounts } from '~/service_accounts/stores/service_accounts';
import { stubComponent } from 'helpers/stub_component';
import { mountExtended } from 'helpers/vue_test_utils_helper';

Vue.use(PiniaVuePlugin);

describe('CreateEditServiceAccountModal', () => {
  let wrapper;

  const pinia = createTestingPinia();
  const store = useServiceAccounts();

  const name = 'My Service Account';

  const createComponent = ({ props = { deleteType: 'soft' }, provide = {} } = {}) => {
    wrapper = mountExtended(CreateEditServiceAccountModal, {
      pinia,
      propsData: {
        name,
        ...props,
      },
      provide: {
        ...provide,
      },
      stubs: {
        GlModal: stubComponent(GlModal),
      },
    });
  };

  const findModal = () => wrapper.findComponent(GlModal);
  const findForm = () => wrapper.findComponent(GlFormFields);
  const findAlert = () => wrapper.findComponent(GlAlert);
  const findCancelButton = () => wrapper.findByTestId('cancel-button');
  const findSubmitButton = () => wrapper.find('button[type=submit]');

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

    describe('when createEditType is "create"', () => {
      beforeEach(() => {
        store.createEditType = 'create';
        createComponent();
      });

      it('renders correct modal title', () => {
        expect(findModal().props('title')).toBe('Create service account');
      });
    });

    describe('when createEditType is "edit"', () => {
      beforeEach(() => {
        store.createEditType = 'edit';
        createComponent();
      });

      it('renders correct modal title', () => {
        expect(findModal().props('title')).toBe('Edit service account');
      });
    });
  });

  describe('form', () => {
    beforeEach(() => {
      store.createEditType = 'create';
      createComponent();
    });

    it('contains correct fields', () => {
      createComponent({
        provide: {
          glFeatures: {
            editServiceAccountEmail: true,
          },
        },
      });

      expect(findForm().props('fields')).toMatchObject({
        name: {
          label: 'Name',
        },
        username: {
          label: 'Username',
        },
        email: {
          label: 'Email',
        },
      });
    });

    it('contains correct label', () => {
      expect(findForm().text()).toContain(
        'Unique username that can be called for usage across GitLab',
      );
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
      describe('when createEditType is "create"', () => {
        it('contains correct text', () => {
          store.createEditType = 'create';
          expect(findSubmitButton().text()).toBe('Create');
        });
      });

      describe('when createEditType is "edit"', () => {
        it('contains correct text', () => {
          store.createEditType = 'edit';
          createComponent();
          expect(findSubmitButton().text()).toBe('Edit');
        });
      });

      it('shows as loading when busy', async () => {
        expect(findSubmitButton().props('loading')).toBe(false);
        store.busy = true;
        await nextTick();

        expect(findSubmitButton().props('loading')).toBe(true);
      });
    });
  });

  describe('alert banner', () => {
    it('shows alert banner when there is a error message', () => {
      store.createEditError = 'An error occurred';
      createComponent();

      expect(findAlert().exists()).toBe(true);
      expect(findAlert().text()).toContain('An error occurred');
    });

    it('hides the alert banner when there is mo error message', () => {
      store.createEditError = '';
      createComponent();

      expect(findAlert().exists()).toBe(false);
    });
  });
});

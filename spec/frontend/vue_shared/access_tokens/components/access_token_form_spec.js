import {
  GlDatepicker,
  GlFormCheckbox,
  GlFormFields,
  GlFormInput,
  GlFormTextarea,
  GlAlert,
} from '@gitlab/ui';
import { createTestingPinia } from '@pinia/testing';
import Vue, { nextTick } from 'vue';
import { PiniaVuePlugin } from 'pinia';
import AccessTokenForm from '~/vue_shared/access_tokens/components/access_token_form.vue';
import { useAccessTokens } from '~/vue_shared/access_tokens/stores/access_tokens';
import { mountExtended } from 'helpers/vue_test_utils_helper';

Vue.use(PiniaVuePlugin);

describe('AccessTokenForm', () => {
  let wrapper;

  const pinia = createTestingPinia();
  const store = useAccessTokens();

  const accessTokenMaxDate = '2021-07-06';
  const accessTokenMinDate = '2020-07-06';
  const accessTokenAvailableScopes = [
    { value: 'read_service_ping', text: 'scope 1' },
    { value: 'read_user', text: 'scope 2' },
    { value: 'other', text: 'scope 3' },
  ];

  const createComponent = (props = {}, provide = {}) => {
    wrapper = mountExtended(AccessTokenForm, {
      pinia,
      provide: {
        accessTokenMaxDate,
        accessTokenMinDate,
        accessTokenAvailableScopes,
        ...provide,
      },
      propsData: {
        ...props,
      },
    });
  };

  const findCheckboxes = () => wrapper.findAllComponents(GlFormCheckbox);
  const findDatepicker = () => wrapper.findComponent(GlDatepicker);
  const findForm = () => wrapper.find('form');
  const findFormFields = () => wrapper.findComponent(GlFormFields);
  const findInput = () => wrapper.findComponent(GlFormInput);
  const findTextArea = () => wrapper.findComponent(GlFormTextarea);
  const findErrorsAlert = () => wrapper.findComponent(GlAlert);
  const findCreateTokenButton = () => wrapper.findByTestId('create-token-button');

  it('contains a name field', () => {
    createComponent();

    expect(findInput().exists()).toBe(true);
  });

  it('contains a description field', () => {
    createComponent();

    expect(findTextArea().exists()).toBe(true);
  });

  describe('expiration field', () => {
    it('contains a datepicker with correct props', () => {
      createComponent();

      const datepicker = findDatepicker();
      expect(datepicker.exists()).toBe(true);
      expect(datepicker.props()).toMatchObject({
        minDate: new Date(accessTokenMinDate),
        maxDate: new Date(accessTokenMaxDate),
      });
    });

    it('removes the expiration date when the datepicker is cleared', async () => {
      createComponent();
      const datepicker = findDatepicker();
      expect(datepicker.props('value')).toBeDefined();
      datepicker.vm.$emit('clear');
      await nextTick();

      expect(datepicker.props('value')).toBeNull();
    });
  });

  it('contains scope checkboxes', () => {
    createComponent();

    const checkboxes = findCheckboxes();
    expect(checkboxes).toHaveLength(3);
    const checkbox = checkboxes.at(0);
    expect(checkbox.find('input').element.value).toBe('read_service_ping');
    expect(checkbox.find('label').text()).toContain('scope 1');
  });

  describe('reset button', () => {
    it('emits a cancel event', () => {
      createComponent();
      expect(store.setShowCreateForm).toHaveBeenCalledTimes(0);
      findForm().trigger('reset');

      expect(store.setShowCreateForm).toHaveBeenCalledWith(false);
    });
  });

  describe('submit button', () => {
    describe('when mandatory fields are empty', () => {
      it('does not create token', () => {
        createComponent();
        findFormFields().trigger('submit');

        expect(store.createToken).toHaveBeenCalledTimes(0);
      });

      it('renders errors alert component', async () => {
        createComponent();
        findCreateTokenButton().trigger('click');

        await nextTick();
        const alert = findErrorsAlert();
        expect(alert.exists()).toBe(true);
      });
    });

    describe('when mandatory fields are filled', () => {
      describe('when the expiration date is mandatory', () => {
        it('creates token if mandatory fields are present', async () => {
          createComponent();
          findInput().setValue('my-token');
          findCheckboxes().at(0).find('input').setChecked();
          await nextTick();
          findFormFields().vm.$emit('submit');

          expect(store.createToken).toHaveBeenCalledWith(
            expect.objectContaining({
              name: 'my-token',
              expiresAt: '2020-08-05',
              scopes: ['read_service_ping'],
            }),
          );
        });
      });

      describe('when the expiration date is not mandatory', () => {
        it('creates token if mandatory fields are present', async () => {
          createComponent({}, { accessTokenMaxDate: null });
          findInput().setValue('my-token');
          findCheckboxes().at(0).find('input').setChecked();
          findDatepicker().vm.$emit('clear');
          await nextTick();
          findFormFields().vm.$emit('submit');

          expect(store.createToken).toHaveBeenCalledWith(
            expect.objectContaining({
              name: 'my-token',
              expiresAt: null,
              scopes: ['read_service_ping'],
            }),
          );
        });
      });
    });
  });

  describe('when token name, description or scopes are provided', () => {
    it('pre-fills the form', () => {
      createComponent({
        name: 'My token',
        description: 'My description',
        scopes: ['read_service_ping', 'read_user'],
      });

      expect(findInput().props('value')).toBe('My token');
      expect(findTextArea().props('value')).toBe('My description');
      expect(findCheckboxes().at(0).find('input').element.checked).toBe(true);
      expect(findCheckboxes().at(1).find('input').element.checked).toBe(true);
      expect(findCheckboxes().at(2).find('input').element.checked).toBe(false);
    });
  });
});

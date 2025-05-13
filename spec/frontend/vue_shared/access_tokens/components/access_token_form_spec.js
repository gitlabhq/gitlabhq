import {
  GlDatepicker,
  GlFormCheckbox,
  GlFormFields,
  GlFormInput,
  GlFormTextarea,
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

  const createComponent = (provide = {}) => {
    wrapper = mountExtended(AccessTokenForm, {
      pinia,
      provide: {
        accessTokenMaxDate,
        accessTokenMinDate,
        ...provide,
      },
    });
  };

  const findCheckboxes = () => wrapper.findAllComponents(GlFormCheckbox);
  const findDatepicker = () => wrapper.findComponent(GlDatepicker);
  const findForm = () => wrapper.find('form');
  const findFormFields = () => wrapper.findComponent(GlFormFields);
  const findInput = () => wrapper.findComponent(GlFormInput);
  const findTextArea = () => wrapper.findComponent(GlFormTextarea);

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
    expect(checkboxes).toHaveLength(13);
    const checkbox = checkboxes.at(0);
    expect(checkbox.find('input').element.value).toBe('read_service_ping');
    expect(checkbox.find('label').text()).toContain(
      'Grant access to download Service Ping payload via API when authenticated as an admin user.',
    );
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
          createComponent();
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
});

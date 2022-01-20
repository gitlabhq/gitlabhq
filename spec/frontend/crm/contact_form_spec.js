import { GlAlert } from '@gitlab/ui';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import ContactForm from '~/crm/components/contact_form.vue';
import createContactMutation from '~/crm/components/queries/create_contact.mutation.graphql';
import updateContactMutation from '~/crm/components/queries/update_contact.mutation.graphql';
import getGroupContactsQuery from '~/crm/components/queries/get_group_contacts.query.graphql';
import {
  createContactMutationErrorResponse,
  createContactMutationResponse,
  getGroupContactsQueryResponse,
  updateContactMutationErrorResponse,
  updateContactMutationResponse,
} from './mock_data';

describe('Customer relations contact form component', () => {
  Vue.use(VueApollo);
  let wrapper;
  let fakeApollo;
  let mutation;
  let queryHandler;

  const findSaveContactButton = () => wrapper.findByTestId('save-contact-button');
  const findCancelButton = () => wrapper.findByTestId('cancel-button');
  const findForm = () => wrapper.find('form');
  const findError = () => wrapper.findComponent(GlAlert);

  const mountComponent = ({ mountFunction = shallowMountExtended, editForm = false } = {}) => {
    fakeApollo = createMockApollo([[mutation, queryHandler]]);
    fakeApollo.clients.defaultClient.cache.writeQuery({
      query: getGroupContactsQuery,
      variables: { groupFullPath: 'flightjs' },
      data: getGroupContactsQueryResponse.data,
    });
    const propsData = { drawerOpen: true };
    if (editForm)
      propsData.contact = { firstName: 'First', lastName: 'Last', email: 'email@example.com' };
    wrapper = mountFunction(ContactForm, {
      provide: { groupId: 26, groupFullPath: 'flightjs' },
      apolloProvider: fakeApollo,
      propsData,
    });
  };

  beforeEach(() => {
    mutation = createContactMutation;
    queryHandler = jest.fn().mockResolvedValue(createContactMutationResponse);
  });

  afterEach(() => {
    wrapper.destroy();
    fakeApollo = null;
  });

  describe('Save contact button', () => {
    it('should be disabled when required fields are empty', () => {
      mountComponent();

      expect(findSaveContactButton().props('disabled')).toBe(true);
    });

    it('should not be disabled when required fields have values', async () => {
      mountComponent();

      wrapper.find('#contact-first-name').vm.$emit('input', 'A');
      wrapper.find('#contact-last-name').vm.$emit('input', 'B');
      wrapper.find('#contact-email').vm.$emit('input', 'C');
      await waitForPromises();

      expect(findSaveContactButton().props('disabled')).toBe(false);
    });
  });

  it("should emit 'close' when cancel button is clicked", () => {
    mountComponent();

    findCancelButton().vm.$emit('click');

    expect(wrapper.emitted().close).toBeTruthy();
  });

  describe('when create mutation is successful', () => {
    it("should emit 'close'", async () => {
      mountComponent();

      findForm().trigger('submit');
      await waitForPromises();

      expect(wrapper.emitted().close).toBeTruthy();
    });
  });

  describe('when create mutation fails', () => {
    it('should show error on reject', async () => {
      queryHandler = jest.fn().mockRejectedValue('ERROR');
      mountComponent();

      findForm().trigger('submit');
      await waitForPromises();

      expect(findError().exists()).toBe(true);
    });

    it('should show error on error response', async () => {
      queryHandler = jest.fn().mockResolvedValue(createContactMutationErrorResponse);
      mountComponent();

      findForm().trigger('submit');
      await waitForPromises();

      expect(findError().exists()).toBe(true);
      expect(findError().text()).toBe('create contact is invalid.');
    });
  });

  describe('when update mutation is successful', () => {
    it("should emit 'close'", async () => {
      mutation = updateContactMutation;
      queryHandler = jest.fn().mockResolvedValue(updateContactMutationResponse);
      mountComponent({ editForm: true });

      findForm().trigger('submit');
      await waitForPromises();

      expect(wrapper.emitted().close).toBeTruthy();
    });
  });

  describe('when update mutation fails', () => {
    beforeEach(() => {
      mutation = updateContactMutation;
    });

    it('should show error on reject', async () => {
      queryHandler = jest.fn().mockRejectedValue('ERROR');
      mountComponent({ editForm: true });
      findForm().trigger('submit');
      await waitForPromises();

      expect(findError().exists()).toBe(true);
    });

    it('should show error on error response', async () => {
      queryHandler = jest.fn().mockResolvedValue(updateContactMutationErrorResponse);
      mountComponent({ editForm: true });

      findForm().trigger('submit');
      await waitForPromises();

      expect(findError().exists()).toBe(true);
      expect(findError().text()).toBe('update contact is invalid.');
    });
  });
});

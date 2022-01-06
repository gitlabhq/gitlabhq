import { GlAlert } from '@gitlab/ui';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import VueRouter from 'vue-router';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import Form from '~/crm/components/form.vue';
import routes from '~/crm/routes';
import createContactMutation from '~/crm/components/queries/create_contact.mutation.graphql';
import updateContactMutation from '~/crm/components/queries/update_contact.mutation.graphql';
import getGroupContactsQuery from '~/crm/components/queries/get_group_contacts.query.graphql';
import createOrganizationMutation from '~/crm/components/queries/create_organization.mutation.graphql';
import getGroupOrganizationsQuery from '~/crm/components/queries/get_group_organizations.query.graphql';
import {
  createContactMutationErrorResponse,
  createContactMutationResponse,
  getGroupContactsQueryResponse,
  updateContactMutationErrorResponse,
  updateContactMutationResponse,
  createOrganizationMutationErrorResponse,
  createOrganizationMutationResponse,
  getGroupOrganizationsQueryResponse,
} from './mock_data';

const FORM_CREATE_CONTACT = 'create contact';
const FORM_UPDATE_CONTACT = 'update contact';
const FORM_CREATE_ORG = 'create organization';

describe('Reusable form component', () => {
  Vue.use(VueApollo);
  Vue.use(VueRouter);

  const DEFAULT_RESPONSES = {
    createContact: Promise.resolve(createContactMutationResponse),
    updateContact: Promise.resolve(updateContactMutationResponse),
    createOrg: Promise.resolve(createOrganizationMutationResponse),
  };

  let wrapper;
  let handler;
  let fakeApollo;
  let router;

  beforeEach(() => {
    router = new VueRouter({
      base: '',
      mode: 'history',
      routes,
    });
    router.push('/test');

    handler = jest.fn().mockImplementation((key) => DEFAULT_RESPONSES[key]);

    const hanlderWithKey = (key) => (...args) => handler(key, ...args);

    fakeApollo = createMockApollo([
      [createContactMutation, hanlderWithKey('createContact')],
      [updateContactMutation, hanlderWithKey('updateContact')],
      [createOrganizationMutation, hanlderWithKey('createOrg')],
    ]);

    fakeApollo.clients.defaultClient.cache.writeQuery({
      query: getGroupContactsQuery,
      variables: { groupFullPath: 'flightjs' },
      data: getGroupContactsQueryResponse.data,
    });

    fakeApollo.clients.defaultClient.cache.writeQuery({
      query: getGroupOrganizationsQuery,
      variables: { groupFullPath: 'flightjs' },
      data: getGroupOrganizationsQueryResponse.data,
    });
  });

  const mockToastShow = jest.fn();

  const findSaveButton = () => wrapper.findByTestId('save-button');
  const findForm = () => wrapper.find('form');
  const findError = () => wrapper.findComponent(GlAlert);

  const mountComponent = (propsData) => {
    wrapper = shallowMountExtended(Form, {
      router,
      apolloProvider: fakeApollo,
      propsData: { drawerOpen: true, ...propsData },
      mocks: {
        $toast: {
          show: mockToastShow,
        },
      },
    });
  };

  const mountContact = ({ propsData } = {}) => {
    mountComponent({
      fields: [
        { name: 'firstName', label: 'First name', required: true },
        { name: 'lastName', label: 'Last name', required: true },
        { name: 'email', label: 'Email', required: true },
        { name: 'phone', label: 'Phone' },
        { name: 'description', label: 'Description' },
      ],
      ...propsData,
    });
  };

  const mountContactCreate = () => {
    const propsData = {
      title: 'New contact',
      successMessage: 'Contact has been added',
      buttonLabel: 'Create contact',
      getQuery: {
        query: getGroupContactsQuery,
        variables: { groupFullPath: 'flightjs' },
      },
      getQueryNodePath: 'group.contacts',
      mutation: createContactMutation,
      additionalCreateParams: { groupId: 'gid://gitlab/Group/26' },
    };
    mountContact({ propsData });
  };

  const mountContactUpdate = () => {
    const propsData = {
      title: 'Edit contact',
      successMessage: 'Contact has been updated',
      mutation: updateContactMutation,
      existingModel: {
        id: 'gid://gitlab/CustomerRelations::Contact/12',
        firstName: 'First',
        lastName: 'Last',
        email: 'email@example.com',
      },
    };
    mountContact({ propsData });
  };

  const mountOrganization = ({ propsData } = {}) => {
    mountComponent({
      fields: [
        { name: 'name', label: 'Name', required: true },
        { name: 'defaultRate', label: 'Default rate', input: { type: 'number', step: '0.01' } },
        { name: 'description', label: 'Description' },
      ],
      ...propsData,
    });
  };

  const mountOrganizationCreate = () => {
    const propsData = {
      title: 'New organization',
      successMessage: 'Organization has been added',
      buttonLabel: 'Create organization',
      getQuery: {
        query: getGroupOrganizationsQuery,
        variables: { groupFullPath: 'flightjs' },
      },
      getQueryNodePath: 'group.organizations',
      mutation: createOrganizationMutation,
      additionalCreateParams: { groupId: 'gid://gitlab/Group/26' },
    };
    mountOrganization({ propsData });
  };

  const forms = {
    [FORM_CREATE_CONTACT]: {
      mountFunction: mountContactCreate,
      mutationErrorResponse: createContactMutationErrorResponse,
      toastMessage: 'Contact has been added',
    },
    [FORM_UPDATE_CONTACT]: {
      mountFunction: mountContactUpdate,
      mutationErrorResponse: updateContactMutationErrorResponse,
      toastMessage: 'Contact has been updated',
    },
    [FORM_CREATE_ORG]: {
      mountFunction: mountOrganizationCreate,
      mutationErrorResponse: createOrganizationMutationErrorResponse,
      toastMessage: 'Organization has been added',
    },
  };
  const asTestParams = (...keys) => keys.map((name) => [name, forms[name]]);

  afterEach(() => {
    wrapper.destroy();
  });

  describe.each(asTestParams(FORM_CREATE_CONTACT, FORM_UPDATE_CONTACT))(
    '%s form save button',
    (name, { mountFunction }) => {
      beforeEach(() => {
        mountFunction();
      });

      it('should be disabled when required fields are empty', async () => {
        wrapper.find('#firstName').vm.$emit('input', '');
        await waitForPromises();

        expect(findSaveButton().props('disabled')).toBe(true);
      });

      it('should not be disabled when required fields have values', async () => {
        wrapper.find('#firstName').vm.$emit('input', 'A');
        wrapper.find('#lastName').vm.$emit('input', 'B');
        wrapper.find('#email').vm.$emit('input', 'C');
        await waitForPromises();

        expect(findSaveButton().props('disabled')).toBe(false);
      });
    },
  );

  describe.each(asTestParams(FORM_CREATE_ORG))('%s form save button', (name, { mountFunction }) => {
    beforeEach(() => {
      mountFunction();
    });

    it('should be disabled when required field is empty', async () => {
      wrapper.find('#name').vm.$emit('input', '');
      await waitForPromises();

      expect(findSaveButton().props('disabled')).toBe(true);
    });

    it('should not be disabled when required field has a value', async () => {
      wrapper.find('#name').vm.$emit('input', 'A');
      await waitForPromises();

      expect(findSaveButton().props('disabled')).toBe(false);
    });
  });

  describe.each(asTestParams(FORM_CREATE_CONTACT, FORM_UPDATE_CONTACT, FORM_CREATE_ORG))(
    'when %s mutation is successful',
    (name, { mountFunction, toastMessage }) => {
      it('form should display correct toast message', async () => {
        mountFunction();

        findForm().trigger('submit');
        await waitForPromises();

        expect(mockToastShow).toHaveBeenCalledWith(toastMessage);
      });
    },
  );

  describe.each(asTestParams(FORM_CREATE_CONTACT, FORM_UPDATE_CONTACT, FORM_CREATE_ORG))(
    'when %s mutation fails',
    (formName, { mutationErrorResponse, mountFunction }) => {
      beforeEach(() => {
        jest.spyOn(console, 'error').mockImplementation();
      });

      it('should show error on reject', async () => {
        handler.mockRejectedValue('ERROR');

        mountFunction();

        findForm().trigger('submit');
        await waitForPromises();

        expect(findError().text()).toBe('Something went wrong. Please try again.');
      });

      it('should show error on error response', async () => {
        handler.mockResolvedValue(mutationErrorResponse);

        mountFunction();

        findForm().trigger('submit');
        await waitForPromises();

        expect(findError().text()).toBe(`${formName} is invalid.`);
      });
    },
  );
});

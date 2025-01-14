import { GlAlert, GlFormCheckbox, GlFormInput, GlFormSelect, GlFormGroup } from '@gitlab/ui';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import VueRouter from 'vue-router';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import CrmForm from '~/crm/components/crm_form.vue';
import routes from '~/crm/contacts/routes';
import createContactMutation from '~/crm/contacts/components/graphql/create_contact.mutation.graphql';
import updateContactMutation from '~/crm/contacts/components/graphql/update_contact.mutation.graphql';
import getGroupContactsQuery from '~/crm/contacts/components/graphql/get_group_contacts.query.graphql';
import createOrganizationMutation from '~/crm/organizations/components/graphql/create_customer_relations_organization.mutation.graphql';
import getGroupOrganizationsQuery from '~/crm/organizations/components/graphql/get_group_organizations.query.graphql';
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

  beforeEach(async () => {
    router = new VueRouter({
      base: '',
      mode: 'history',
      routes,
    });
    await router.push('/new');

    handler = jest.fn().mockImplementation((key) => DEFAULT_RESPONSES[key]);

    const hanlderWithKey =
      (key) =>
      (...args) =>
        handler(key, ...args);

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
  const findFormGroup = (at) => wrapper.findAllComponents(GlFormGroup).at(at);

  const mountComponent = (propsData) => {
    wrapper = shallowMountExtended(CrmForm, {
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

  const mountContact = ({ propsData, extraFields = [] } = {}) => {
    mountComponent({
      fields: [
        { name: 'firstName', label: 'First name', required: true },
        { name: 'lastName', label: 'Last name', required: true },
        { name: 'email', label: 'Email', required: true },
        { name: 'phone', label: 'Phone' },
        { name: 'description', label: 'Description' },
        {
          name: 'organizationId',
          label: 'Organization',
          values: [
            { key: 'gid://gitlab/CustomerRelations::Organization/1', value: 'GitLab' },
            { key: 'gid://gitlab/CustomerRelations::Organization/2', value: 'ABC Corp' },
          ],
        },
        ...extraFields,
      ],
      getQuery: {
        query: getGroupContactsQuery,
        variables: { groupFullPath: 'flightjs' },
      },
      getQueryNodePath: 'group.contacts',
      ...propsData,
    });
  };

  const mountContactCreate = () => {
    const propsData = {
      title: 'New contact',
      successMessage: 'Contact has been added.',
      buttonLabel: 'Create contact',
      mutation: createContactMutation,
      additionalCreateParams: { groupId: 'gid://gitlab/Group/26' },
    };
    mountContact({ propsData });
  };

  const mountContactUpdate = () => {
    const propsData = {
      title: 'Edit contact',
      successMessage: 'Contact has been updated.',
      mutation: updateContactMutation,
      existingId: 'gid://gitlab/CustomerRelations::Contact/12',
    };
    const extraFields = [{ name: 'active', label: 'Active', required: true, bool: true }];
    mountContact({ propsData, extraFields });
  };

  const mountOrganization = ({ propsData } = {}) => {
    mountComponent({
      fields: [
        { name: 'name', label: 'Name', required: true },
        { name: 'defaultRate', label: 'Default rate', input: { type: 'number', step: '0.01' } },
        { name: 'description', label: 'Description' },
      ],
      getQuery: {
        query: getGroupOrganizationsQuery,
        variables: { groupFullPath: 'flightjs' },
      },
      getQueryNodePath: 'group.organizations',
      ...propsData,
    });
  };

  const mountOrganizationCreate = () => {
    const propsData = {
      title: 'New organization',
      successMessage: 'Organization has been added.',
      buttonLabel: 'Create organization',
      mutation: createOrganizationMutation,
      additionalCreateParams: { groupId: 'gid://gitlab/Group/26' },
    };
    mountOrganization({ propsData });
  };

  const forms = {
    [FORM_CREATE_CONTACT]: {
      mountFunction: mountContactCreate,
      mutationErrorResponse: createContactMutationErrorResponse,
      toastMessage: 'Contact has been added.',
    },
    [FORM_UPDATE_CONTACT]: {
      mountFunction: mountContactUpdate,
      mutationErrorResponse: updateContactMutationErrorResponse,
      toastMessage: 'Contact has been updated.',
    },
    [FORM_CREATE_ORG]: {
      mountFunction: mountOrganizationCreate,
      mutationErrorResponse: createOrganizationMutationErrorResponse,
      toastMessage: 'Organization has been added.',
    },
  };
  const asTestParams = (...keys) => keys.map((name) => [name, forms[name]]);

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

  describe('edit form', () => {
    beforeEach(() => {
      mountContactUpdate();
    });

    it.each`
      index | id                  | component       | value
      ${0}  | ${'firstName'}      | ${GlFormInput}  | ${'Marty'}
      ${1}  | ${'lastName'}       | ${GlFormInput}  | ${'McFly'}
      ${2}  | ${'email'}          | ${GlFormInput}  | ${'example@gitlab.com'}
      ${4}  | ${'description'}    | ${GlFormInput}  | ${undefined}
      ${3}  | ${'phone'}          | ${GlFormInput}  | ${undefined}
      ${5}  | ${'organizationId'} | ${GlFormSelect} | ${'gid://gitlab/CustomerRelations::Organization/2'}
    `(
      'should render the correct component for #$id with the value "$value"',
      ({ index, id, component, value }) => {
        const findFormElement = () => findFormGroup(index).findComponent(component);

        expect(findFormElement().attributes('id')).toBe(id);
        expect(findFormElement().attributes('value')).toBe(value);
      },
    );

    it('should render a checked GlFormCheckbox for #active', () => {
      const activeCheckboxIndex = 6;
      const findFormElement = () =>
        findFormGroup(activeCheckboxIndex).findComponent(GlFormCheckbox);

      expect(findFormElement().attributes('id')).toBe('active');
      expect(findFormElement().attributes('checked')).toBe('true');
    });

    it('should include updated values in update mutation', () => {
      wrapper.find('#firstName').vm.$emit('input', 'Michael');
      wrapper
        .find('#organizationId')
        .vm.$emit('input', 'gid://gitlab/CustomerRelations::Organization/1');

      findForm().trigger('submit');

      expect(handler).toHaveBeenCalledWith('updateContact', {
        input: {
          active: true,
          description: null,
          email: 'example@gitlab.com',
          firstName: 'Michael',
          id: 'gid://gitlab/CustomerRelations::Contact/12',
          lastName: 'McFly',
          organizationId: 'gid://gitlab/CustomerRelations::Organization/1',
          phone: null,
        },
      });
    });
  });
});

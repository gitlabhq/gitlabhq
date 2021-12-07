import { GlAlert } from '@gitlab/ui';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import NewContactForm from '~/crm/components/new_contact_form.vue';
import createContactMutation from '~/crm/components/queries/create_contact.mutation.graphql';
import getGroupContactsQuery from '~/crm/components/queries/get_group_contacts.query.graphql';
import {
  createContactMutationErrorResponse,
  createContactMutationResponse,
  getGroupContactsQueryResponse,
} from './mock_data';

describe('Customer relations contacts root app', () => {
  Vue.use(VueApollo);
  let wrapper;
  let fakeApollo;
  let queryHandler;

  const findCreateNewContactButton = () => wrapper.findByTestId('create-new-contact-button');
  const findCancelButton = () => wrapper.findByTestId('cancel-button');
  const findForm = () => wrapper.find('form');
  const findError = () => wrapper.findComponent(GlAlert);

  const mountComponent = ({ mountFunction = shallowMountExtended } = {}) => {
    fakeApollo = createMockApollo([[createContactMutation, queryHandler]]);
    fakeApollo.clients.defaultClient.cache.writeQuery({
      query: getGroupContactsQuery,
      variables: { groupFullPath: 'flightjs' },
      data: getGroupContactsQueryResponse.data,
    });
    wrapper = mountFunction(NewContactForm, {
      provide: { groupId: 26, groupFullPath: 'flightjs' },
      apolloProvider: fakeApollo,
      propsData: { drawerOpen: true },
    });
  };

  beforeEach(() => {
    queryHandler = jest.fn().mockResolvedValue(createContactMutationResponse);
  });

  afterEach(() => {
    wrapper.destroy();
    fakeApollo = null;
  });

  describe('Create new contact button', () => {
    it('should be disabled by default', () => {
      mountComponent();

      expect(findCreateNewContactButton().attributes('disabled')).toBeTruthy();
    });

    it('should not be disabled when first, last and email have values', async () => {
      mountComponent();

      wrapper.find('#contact-first-name').vm.$emit('input', 'A');
      wrapper.find('#contact-last-name').vm.$emit('input', 'B');
      wrapper.find('#contact-email').vm.$emit('input', 'C');
      await waitForPromises();

      expect(findCreateNewContactButton().attributes('disabled')).toBeFalsy();
    });
  });

  it("should emit 'close' when cancel button is clicked", () => {
    mountComponent();

    findCancelButton().vm.$emit('click');

    expect(wrapper.emitted().close).toBeTruthy();
  });

  describe('when query is successful', () => {
    it("should emit 'close'", async () => {
      mountComponent();

      findForm().trigger('submit');
      await waitForPromises();

      expect(wrapper.emitted().close).toBeTruthy();
    });
  });

  describe('when query fails', () => {
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
      expect(findError().text()).toBe('Phone is invalid.');
    });
  });
});

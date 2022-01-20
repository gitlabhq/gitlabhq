import { GlAlert } from '@gitlab/ui';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import NewOrganizationForm from '~/crm/components/new_organization_form.vue';
import createOrganizationMutation from '~/crm/components/queries/create_organization.mutation.graphql';
import getGroupOrganizationsQuery from '~/crm/components/queries/get_group_organizations.query.graphql';
import {
  createOrganizationMutationErrorResponse,
  createOrganizationMutationResponse,
  getGroupOrganizationsQueryResponse,
} from './mock_data';

describe('Customer relations organizations root app', () => {
  Vue.use(VueApollo);
  let wrapper;
  let fakeApollo;
  let queryHandler;

  const findCreateNewOrganizationButton = () =>
    wrapper.findByTestId('create-new-organization-button');
  const findCancelButton = () => wrapper.findByTestId('cancel-button');
  const findForm = () => wrapper.find('form');
  const findError = () => wrapper.findComponent(GlAlert);

  const mountComponent = () => {
    fakeApollo = createMockApollo([[createOrganizationMutation, queryHandler]]);
    fakeApollo.clients.defaultClient.cache.writeQuery({
      query: getGroupOrganizationsQuery,
      variables: { groupFullPath: 'flightjs' },
      data: getGroupOrganizationsQueryResponse.data,
    });
    wrapper = shallowMountExtended(NewOrganizationForm, {
      provide: { groupId: 26, groupFullPath: 'flightjs' },
      apolloProvider: fakeApollo,
      propsData: { drawerOpen: true },
    });
  };

  beforeEach(() => {
    queryHandler = jest.fn().mockResolvedValue(createOrganizationMutationResponse);
  });

  afterEach(() => {
    wrapper.destroy();
    fakeApollo = null;
  });

  describe('Create new organization button', () => {
    it('should be disabled by default', () => {
      mountComponent();

      expect(findCreateNewOrganizationButton().attributes('disabled')).toBeTruthy();
    });

    it('should not be disabled when first, last and email have values', async () => {
      mountComponent();

      wrapper.find('#organization-name').vm.$emit('input', 'A');
      await waitForPromises();

      expect(findCreateNewOrganizationButton().attributes('disabled')).toBeFalsy();
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
      queryHandler = jest.fn().mockResolvedValue(createOrganizationMutationErrorResponse);
      mountComponent();

      findForm().trigger('submit');
      await waitForPromises();

      expect(findError().exists()).toBe(true);
      expect(findError().text()).toBe('create organization is invalid.');
    });
  });
});

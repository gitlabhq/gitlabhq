import { GlButton, GlForm } from '@gitlab/ui';
import VueApollo from 'vue-apollo';
import Vue, { nextTick } from 'vue';

import { mountExtended } from 'helpers/vue_test_utils_helper';
import ChangeUrl from '~/organizations/settings/general/components/change_url.vue';
import resolvers from '~/organizations/shared/graphql/resolvers';
import { updateOrganizationResponse } from '~/organizations/mock_data';
import { createAlert } from '~/alert';
import { visitUrlWithAlerts } from '~/lib/utils/url_utility';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';

jest.mock('~/alert');
jest.mock('~/lib/utils/url_utility', () => ({
  ...jest.requireActual('~/lib/utils/url_utility'),
  visitUrlWithAlerts: jest.fn(),
}));
jest.useFakeTimers();

Vue.use(VueApollo);

describe('ChangeUrl', () => {
  let wrapper;
  let mockApollo;

  const defaultProvide = {
    organization: {
      id: 1,
      name: 'GitLab',
      path: 'foo-bar',
    },
    organizationsPath: '/-/organizations',
    rootUrl: 'http://127.0.0.1:3000/',
  };

  const createComponent = ({ mockResolvers = resolvers } = {}) => {
    mockApollo = createMockApollo([], mockResolvers);

    wrapper = mountExtended(ChangeUrl, {
      attachTo: document.body,
      provide: defaultProvide,
      apolloProvider: mockApollo,
    });
  };

  const findSubmitButton = () => wrapper.findComponent(GlButton);
  const findOrganizationUrlField = () => wrapper.findByLabelText('Organization URL');
  const submitForm = async () => {
    await wrapper.findComponent(GlForm).trigger('submit');
    await nextTick();
  };

  afterEach(() => {
    mockApollo = null;
  });

  it('renders `Organization URL` field', () => {
    createComponent();

    expect(findOrganizationUrlField().exists()).toBe(true);
  });

  it('disables submit button until `Organization URL` field is changed', async () => {
    createComponent();

    expect(findSubmitButton().props('disabled')).toBe(true);

    await findOrganizationUrlField().setValue('foo-bar-baz');

    expect(findSubmitButton().props('disabled')).toBe(false);
  });

  describe('when form is submitted', () => {
    it('requires `Organization URL` field', async () => {
      createComponent();

      await findOrganizationUrlField().setValue('');
      await submitForm();

      expect(wrapper.findByText('Organization URL is required.').exists()).toBe(true);
    });

    it('requires `Organization URL` field to be a minimum of two characters', async () => {
      createComponent();

      await findOrganizationUrlField().setValue('f');
      await submitForm();

      expect(
        wrapper.findByText('Organization URL is too short (minimum is 2 characters).').exists(),
      ).toBe(true);
    });

    describe('when API is loading', () => {
      beforeEach(async () => {
        const mockResolvers = {
          Mutation: {
            updateOrganization: jest.fn().mockReturnValueOnce(new Promise(() => {})),
          },
        };

        createComponent({ mockResolvers });

        await findOrganizationUrlField().setValue('foo-bar-baz');
        await submitForm();
      });

      it('shows submit button as loading', () => {
        expect(findSubmitButton().props('loading')).toBe(true);
      });
    });

    describe('when API request is successful', () => {
      beforeEach(async () => {
        createComponent();
        await findOrganizationUrlField().setValue('foo-bar-baz');
        await submitForm();
        jest.runAllTimers();
        await waitForPromises();
      });

      it('redirects user to new organization settings page and shows success alert', () => {
        expect(visitUrlWithAlerts).toHaveBeenCalledWith(
          `${updateOrganizationResponse.organization.webUrl}/settings/general`,
          [
            {
              id: 'organization-url-successfully-changed',
              message: 'Organization URL successfully changed.',
              variant: 'info',
            },
          ],
        );
      });
    });

    describe('when API request is not successful', () => {
      const error = new Error();

      beforeEach(async () => {
        const mockResolvers = {
          Mutation: {
            updateOrganization: jest.fn().mockRejectedValueOnce(error),
          },
        };

        createComponent({ mockResolvers });
        await findOrganizationUrlField().setValue('foo-bar-baz');
        await submitForm();
        jest.runAllTimers();
        await waitForPromises();
      });

      it('displays error alert', () => {
        expect(createAlert).toHaveBeenCalledWith({
          message: 'An error occurred changing your organization URL. Please try again.',
          error,
          captureError: true,
        });
      });
    });
  });
});

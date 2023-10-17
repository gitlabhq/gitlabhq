import VueApollo from 'vue-apollo';
import Vue, { nextTick } from 'vue';

import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import App from '~/organizations/new/components/app.vue';
import resolvers from '~/organizations/shared/graphql/resolvers';
import NewEditForm from '~/organizations/shared/components/new_edit_form.vue';
import { visitUrl } from '~/lib/utils/url_utility';
import { createOrganizationResponse } from '~/organizations/mock_data';
import { createAlert } from '~/alert';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';

Vue.use(VueApollo);
jest.useFakeTimers();

jest.mock('~/lib/utils/url_utility');
jest.mock('~/alert');

describe('OrganizationNewApp', () => {
  let wrapper;
  let mockApollo;

  const createComponent = ({ mockResolvers = resolvers } = {}) => {
    mockApollo = createMockApollo([], mockResolvers);

    wrapper = shallowMountExtended(App, { apolloProvider: mockApollo });
  };

  const findForm = () => wrapper.findComponent(NewEditForm);
  const submitForm = async () => {
    findForm().vm.$emit('submit', { name: 'Foo bar', path: 'foo-bar' });
    await nextTick();
  };

  afterEach(() => {
    mockApollo = null;
  });

  it('renders form', () => {
    createComponent();

    expect(findForm().exists()).toBe(true);
  });

  describe('when form is submitted', () => {
    describe('when API is loading', () => {
      beforeEach(async () => {
        const mockResolvers = {
          Mutation: {
            createOrganization: jest.fn().mockReturnValueOnce(new Promise(() => {})),
          },
        };

        createComponent({ mockResolvers });

        await submitForm();
      });

      it('sets `NewEditForm` `loading` prop to `true`', () => {
        expect(findForm().props('loading')).toBe(true);
      });
    });

    describe('when API request is successful', () => {
      beforeEach(async () => {
        createComponent();
        await submitForm();
        jest.runAllTimers();
        await waitForPromises();
      });

      it('redirects user to organization path', () => {
        expect(visitUrl).toHaveBeenCalledWith(createOrganizationResponse.organization.path);
      });
    });

    describe('when API request is not successful', () => {
      const error = new Error();

      beforeEach(async () => {
        const mockResolvers = {
          Mutation: {
            createOrganization: jest.fn().mockRejectedValueOnce(error),
          },
        };

        createComponent({ mockResolvers });
        await submitForm();
        jest.runAllTimers();
        await waitForPromises();
      });

      it('displays error alert', () => {
        expect(createAlert).toHaveBeenCalledWith({
          message: 'An error occurred creating an organization. Please try again.',
          error,
          captureError: true,
        });
      });
    });
  });
});

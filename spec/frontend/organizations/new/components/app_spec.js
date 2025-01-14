import VueApollo from 'vue-apollo';
import Vue, { nextTick } from 'vue';

import organizationCreateResponse from 'test_fixtures/graphql/organizations/organization_create.mutation.graphql.json';
import organizationCreateResponseWithErrors from 'test_fixtures/graphql/organizations/organization_create.mutation.graphql_with_errors.json';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import App from '~/organizations/new/components/app.vue';
import organizationCreateMutation from '~/organizations/new/graphql/mutations/organization_create.mutation.graphql';
import NewEditForm from '~/organizations/shared/components/new_edit_form.vue';
import FormErrorsAlert from '~/organizations/shared/components/errors_alert.vue';
import { visitUrlWithAlerts } from '~/lib/utils/url_utility';
import { createAlert } from '~/alert';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';

Vue.use(VueApollo);

jest.mock('~/lib/utils/url_utility');
jest.mock('~/alert');

describe('OrganizationNewApp', () => {
  let wrapper;
  let mockApollo;

  const file = new File(['foo'], 'foo.jpg', {
    type: 'text/plain',
  });

  const successfulResponseHandler = jest.fn().mockResolvedValue(organizationCreateResponse);

  const createComponent = ({
    handlers = [[organizationCreateMutation, successfulResponseHandler]],
  } = {}) => {
    mockApollo = createMockApollo(handlers);

    wrapper = shallowMountExtended(App, { apolloProvider: mockApollo });
  };

  const findForm = () => wrapper.findComponent(NewEditForm);
  const submitForm = async () => {
    findForm().vm.$emit('submit', {
      name: 'Foo bar',
      path: 'foo-bar',
      description: 'Foo bar description',
      avatar: file,
    });
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
        createComponent({
          handlers: [
            [organizationCreateMutation, jest.fn().mockReturnValueOnce(new Promise(() => {}))],
          ],
        });

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
        await waitForPromises();
      });

      it('calls mutation with correct variables and redirects user to organization web url', () => {
        expect(successfulResponseHandler).toHaveBeenCalledWith({
          input: {
            name: 'Foo bar',
            path: 'foo-bar',
            description: 'Foo bar description',
            avatar: file,
          },
        });
        expect(visitUrlWithAlerts).toHaveBeenCalledWith(
          organizationCreateResponse.data.organizationCreate.organization.webUrl,
          [
            {
              id: 'organization-successfully-created',
              title: 'Organization successfully created.',
              message: 'You can now start using your new organization.',
              variant: 'success',
            },
          ],
        );
      });
    });

    describe('when API request is not successful', () => {
      describe('when there is a network error', () => {
        const error = new Error();

        beforeEach(async () => {
          createComponent({
            handlers: [[organizationCreateMutation, jest.fn().mockRejectedValue(error)]],
          });
          await submitForm();
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

      describe('when there are GraphQL errors', () => {
        beforeEach(async () => {
          createComponent({
            handlers: [
              [
                organizationCreateMutation,
                jest.fn().mockResolvedValue(organizationCreateResponseWithErrors),
              ],
            ],
          });
          await submitForm();
          await waitForPromises();
        });

        it('displays form errors alert', () => {
          expect(wrapper.findComponent(FormErrorsAlert).props()).toStrictEqual({
            errors: organizationCreateResponseWithErrors.data.organizationCreate.errors,
            scrollOnError: true,
          });
        });
      });
    });
  });
});

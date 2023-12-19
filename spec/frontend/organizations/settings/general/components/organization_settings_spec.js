import VueApollo from 'vue-apollo';
import Vue, { nextTick } from 'vue';

import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import OrganizationSettings from '~/organizations/settings/general/components/organization_settings.vue';
import SettingsBlock from '~/vue_shared/components/settings/settings_block.vue';
import NewEditForm from '~/organizations/shared/components/new_edit_form.vue';
import { FORM_FIELD_NAME, FORM_FIELD_ID } from '~/organizations/shared/constants';
import organizationUpdateMutation from '~/organizations/settings/general/graphql/mutations/organization_update.mutation.graphql';
import {
  organizationUpdateResponse,
  organizationUpdateResponseWithErrors,
} from '~/organizations/mock_data';
import { createAlert } from '~/alert';
import { visitUrlWithAlerts } from '~/lib/utils/url_utility';
import FormErrorsAlert from '~/vue_shared/components/form/errors_alert.vue';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { useMockLocationHelper } from 'helpers/mock_window_location_helper';

Vue.use(VueApollo);
jest.mock('~/alert');
jest.mock('~/lib/utils/url_utility', () => ({
  ...jest.requireActual('~/lib/utils/url_utility'),
  visitUrlWithAlerts: jest.fn(),
}));

useMockLocationHelper();

describe('OrganizationSettings', () => {
  let wrapper;
  let mockApollo;

  const defaultProvide = {
    organization: {
      id: 1,
      name: 'GitLab',
    },
  };

  const successfulResponseHandler = jest.fn().mockResolvedValue(organizationUpdateResponse);

  const createComponent = ({
    handlers = [[organizationUpdateMutation, successfulResponseHandler]],
  } = {}) => {
    mockApollo = createMockApollo(handlers);

    wrapper = shallowMountExtended(OrganizationSettings, {
      provide: defaultProvide,
      apolloProvider: mockApollo,
    });
  };

  const findForm = () => wrapper.findComponent(NewEditForm);
  const submitForm = async () => {
    findForm().vm.$emit('submit', { name: 'Foo bar', path: 'foo-bar' });
    await nextTick();
  };

  beforeEach(() => {
    createComponent();
  });

  afterEach(() => {
    mockApollo = null;
  });

  it('renders settings block', () => {
    expect(wrapper.findComponent(SettingsBlock).exists()).toBe(true);
  });

  it('renders form with correct props', () => {
    createComponent();

    expect(findForm().props()).toMatchObject({
      loading: false,
      initialFormValues: defaultProvide.organization,
      fieldsToRender: [FORM_FIELD_NAME, FORM_FIELD_ID],
    });
  });

  describe('when form is submitted', () => {
    describe('when API is loading', () => {
      beforeEach(async () => {
        createComponent({
          handlers: [
            [organizationUpdateMutation, jest.fn().mockReturnValueOnce(new Promise(() => {}))],
          ],
        });

        await submitForm();
      });

      it('sets form `loading` prop to `true`', () => {
        expect(findForm().props('loading')).toBe(true);
      });
    });

    describe('when API request is successful', () => {
      beforeEach(async () => {
        createComponent();
        await submitForm();
        await waitForPromises();
      });

      it('calls mutation with correct variables and displays info alert', () => {
        expect(successfulResponseHandler).toHaveBeenCalledWith({
          input: {
            id: 'gid://gitlab/Organizations::Organization/1',
            name: 'Foo bar',
          },
        });
        expect(visitUrlWithAlerts).toHaveBeenCalledWith(window.location.href, [
          {
            id: 'organization-successfully-updated',
            message: 'Organization was successfully updated.',
            variant: 'info',
          },
        ]);
      });
    });

    describe('when API request is not successful', () => {
      describe('when there is a network error', () => {
        const error = new Error();

        beforeEach(async () => {
          createComponent({
            handlers: [[organizationUpdateMutation, jest.fn().mockRejectedValue(error)]],
          });
          await submitForm();
          await waitForPromises();
        });

        it('displays error alert', () => {
          expect(createAlert).toHaveBeenCalledWith({
            message: 'An error occurred updating your organization. Please try again.',
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
                organizationUpdateMutation,
                jest.fn().mockResolvedValue(organizationUpdateResponseWithErrors),
              ],
            ],
          });
          await submitForm();
          await waitForPromises();
        });

        it('displays form errors alert', () => {
          expect(wrapper.findComponent(FormErrorsAlert).props('errors')).toEqual(
            organizationUpdateResponseWithErrors.data.organizationUpdate.errors,
          );
        });
      });
    });
  });
});

import VueApollo from 'vue-apollo';
import Vue, { nextTick } from 'vue';
import { GlSprintf } from '@gitlab/ui';

import organizationUpdateResponse from 'test_fixtures/graphql/organizations/organization_update.mutation.graphql.json';
import organizationUpdateResponseWithErrors from 'test_fixtures/graphql/organizations/organization_update.mutation.graphql_with_errors.json';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import OrganizationSettings from '~/organizations/settings/general/components/organization_settings.vue';
import SettingsBlock from '~/vue_shared/components/settings/settings_block.vue';
import NewEditForm from '~/organizations/shared/components/new_edit_form.vue';
import {
  FORM_FIELD_NAME,
  FORM_FIELD_ID,
  FORM_FIELD_AVATAR,
  FORM_FIELD_DESCRIPTION,
} from '~/organizations/shared/constants';
import FormErrorsAlert from '~/organizations/shared/components/errors_alert.vue';
import HelpPageLink from '~/vue_shared/components/help_page_link/help_page_link.vue';
import organizationUpdateMutation from '~/organizations/settings/general/graphql/mutations/organization_update.mutation.graphql';
import { createAlert } from '~/alert';
import { visitUrlWithAlerts } from '~/lib/utils/url_utility';
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

  const defaultPropsData = {
    id: 'organization-settings',
    expanded: false,
  };

  const file = new File(['foo'], 'foo.jpg', {
    type: 'text/plain',
  });

  const successfulResponseHandler = jest.fn().mockResolvedValue(organizationUpdateResponse);

  const findSettingsBlock = () => wrapper.findComponent(SettingsBlock);

  const createComponent = ({
    handlers = [[organizationUpdateMutation, successfulResponseHandler]],
    provide = {},
    propsData = {},
  } = {}) => {
    mockApollo = createMockApollo(handlers);

    wrapper = shallowMountExtended(OrganizationSettings, {
      provide: { ...defaultProvide, ...provide },
      propsData: { ...defaultPropsData, ...propsData },
      apolloProvider: mockApollo,
      stubs: { GlSprintf },
    });
  };

  const findForm = () => wrapper.findComponent(NewEditForm);
  const findHelpPageLink = () => wrapper.findComponent(HelpPageLink);
  const submitForm = async (data = {}) => {
    findForm().vm.$emit('submit', {
      name: 'Foo bar',
      path: 'foo-bar',
      description: 'Foo bar description',
      avatar: file,
      ...data,
    });
    await nextTick();
  };

  beforeEach(() => {
    createComponent();
  });

  afterEach(() => {
    mockApollo = null;
  });

  it('renders settings block with correct props and link to docs', () => {
    expect(wrapper.findComponent(SettingsBlock).exists()).toBe(true);
    expect(findHelpPageLink().text()).toBe('Learn more about organizations');
    expect(findHelpPageLink().props('href')).toBe('user/organization/_index.md');
  });

  it('renders form with correct props', () => {
    createComponent();

    expect(findForm().props()).toMatchObject({
      loading: false,
      initialFormValues: defaultProvide.organization,
      fieldsToRender: [FORM_FIELD_NAME, FORM_FIELD_ID, FORM_FIELD_DESCRIPTION, FORM_FIELD_AVATAR],
    });
  });

  describe('when SettingsBlock component emits `toggle-expand` event', () => {
    beforeEach(() => {
      findSettingsBlock().vm.$emit('toggle-expand', true);
    });

    it('emits `toggle-expand` event', () => {
      expect(wrapper.emitted('toggle-expand')).toEqual([[true]]);
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
            description: 'Foo bar description',
            avatar: file,
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
          expect(wrapper.findComponent(FormErrorsAlert).props()).toStrictEqual({
            errors: organizationUpdateResponseWithErrors.data.organizationUpdate.errors,
            scrollOnError: true,
          });
        });
      });
    });

    describe('when organization has avatar', () => {
      beforeEach(() => {
        createComponent({
          provide: { organization: { ...defaultProvide.organization, avatar: 'avatar.jpg' } },
        });
      });

      describe('when avatar is explicitly removed', () => {
        beforeEach(async () => {
          await submitForm({ avatar: null });
          await waitForPromises();
        });

        it('sets `avatar` argument to `null`', () => {
          expect(successfulResponseHandler).toHaveBeenCalledWith({
            input: {
              id: 'gid://gitlab/Organizations::Organization/1',
              name: 'Foo bar',
              description: 'Foo bar description',
              avatar: null,
            },
          });
        });
      });

      describe('when avatar is not changed', () => {
        beforeEach(async () => {
          await submitForm({ avatar: 'avatar.jpg' });
          await waitForPromises();
        });

        it('does not pass `avatar` argument', () => {
          expect(successfulResponseHandler).toHaveBeenCalledWith({
            input: {
              id: 'gid://gitlab/Organizations::Organization/1',
              name: 'Foo bar',
              description: 'Foo bar description',
            },
          });
        });
      });
    });
  });
});

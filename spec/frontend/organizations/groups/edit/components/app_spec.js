import { GlSprintf } from '@gitlab/ui';
import VueApollo from 'vue-apollo';
import Vue, { nextTick } from 'vue';

import groupUpdateResponse from 'test_fixtures/graphql/organizations/group_update.mutation.graphql.json';
import groupUpdateResponseWithErrors from 'test_fixtures/graphql/organizations/group_update.mutation.graphql_with_errors.json';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import App from '~/organizations/groups/edit/components/app.vue';
import groupUpdateMutation from '~/organizations/groups/edit/graphql/mutations/group_update.mutation.graphql';
import FormErrorsAlert from '~/organizations/shared/components/errors_alert.vue';
import {
  VISIBILITY_LEVEL_INTERNAL_INTEGER,
  VISIBILITY_LEVEL_PRIVATE_INTEGER,
  VISIBILITY_LEVEL_PUBLIC_INTEGER,
  VISIBILITY_LEVEL_PRIVATE_STRING,
} from '~/visibility_level/constants';
import NewEditForm from '~/groups/components/new_edit_form.vue';
import { createAlert } from '~/alert';
import { visitUrlWithAlerts } from '~/lib/utils/url_utility';
import { FORM_FIELD_NAME, FORM_FIELD_PATH, FORM_FIELD_VISIBILITY_LEVEL } from '~/groups/constants';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';

jest.mock('~/lib/utils/url_utility');
jest.mock('~/alert');

Vue.use(VueApollo);

describe('OrganizationGroupsEditApp', () => {
  let wrapper;
  let mockApollo;

  const defaultProvide = {
    group: {
      id: 1,
      fullName: 'Mock namespace / Foo bar',
      name: 'Foo bar',
      path: 'foo-bar',
      fullPath: 'mock-namespace/foo-bar',
    },
    basePath: 'https://gitlab.com',
    groupsAndProjectsOrganizationPath: '/-/organizations/carrot/groups_and_projects?display=groups',
    groupsOrganizationPath: '/-/organizations/default/groups',
    availableVisibilityLevels: [
      VISIBILITY_LEVEL_PRIVATE_INTEGER,
      VISIBILITY_LEVEL_INTERNAL_INTEGER,
      VISIBILITY_LEVEL_PUBLIC_INTEGER,
    ],
    restrictedVisibilityLevels: [],
    defaultVisibilityLevel: VISIBILITY_LEVEL_INTERNAL_INTEGER,
    pathMaxlength: 10,
    pathPattern: 'mockPattern',
  };

  const successfulResponseHandler = jest.fn().mockResolvedValue(groupUpdateResponse);

  const createComponent = ({
    handlers = [[groupUpdateMutation, successfulResponseHandler]],
  } = {}) => {
    mockApollo = createMockApollo(handlers);

    wrapper = shallowMountExtended(App, {
      apolloProvider: mockApollo,
      provide: defaultProvide,
      stubs: {
        GlSprintf,
      },
    });
  };

  const findForm = () => wrapper.findComponent(NewEditForm);
  const submitForm = async () => {
    findForm().vm.$emit('submit', {
      [FORM_FIELD_NAME]: 'Foo bar',
      [FORM_FIELD_PATH]: 'foo-bar',
      [FORM_FIELD_VISIBILITY_LEVEL]: VISIBILITY_LEVEL_PRIVATE_INTEGER,
    });
    await nextTick();
  };

  afterEach(() => {
    mockApollo = null;
  });

  it('renders page title', () => {
    createComponent();

    expect(
      wrapper.findByRole('heading', { name: 'Edit group: Mock namespace / Foo bar' }).exists(),
    ).toBe(true);
  });

  it('renders form and passes correct props', () => {
    createComponent();

    expect(findForm().props()).toEqual({
      loading: false,
      basePath: defaultProvide.basePath,
      cancelPath: defaultProvide.groupsAndProjectsOrganizationPath,
      pathMaxlength: defaultProvide.pathMaxlength,
      pathPattern: defaultProvide.pathPattern,
      availableVisibilityLevels: defaultProvide.availableVisibilityLevels,
      restrictedVisibilityLevels: defaultProvide.restrictedVisibilityLevels,
      initialFormValues: defaultProvide.group,
      submitButtonText: 'Save changes',
    });
  });

  describe('when form is submitted', () => {
    describe('when API is loading', () => {
      beforeEach(async () => {
        createComponent();

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
            fullPath: defaultProvide.group.fullPath,
            name: 'Foo bar',
            path: 'foo-bar',
            visibility: VISIBILITY_LEVEL_PRIVATE_STRING,
          },
        });
        expect(visitUrlWithAlerts).toHaveBeenCalledWith(
          groupUpdateResponse.data.groupUpdate.group.organizationEditPath,
          [
            {
              id: 'organization-group-successfully-updated',
              message: 'Group was successfully updated.',
              variant: 'info',
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
            handlers: [[groupUpdateMutation, jest.fn().mockRejectedValue(error)]],
          });
          await submitForm();
          await waitForPromises();
        });

        it('displays error alert', () => {
          expect(createAlert).toHaveBeenCalledWith({
            message: 'An error occurred updating this group. Please try again.',
            error,
            captureError: true,
          });
        });
      });

      describe('when there are GraphQL errors', () => {
        beforeEach(async () => {
          createComponent({
            handlers: [
              [groupUpdateMutation, jest.fn().mockResolvedValue(groupUpdateResponseWithErrors)],
            ],
          });
          await submitForm();
          await waitForPromises();
        });

        it('displays form errors alert', () => {
          expect(wrapper.findComponent(FormErrorsAlert).props()).toStrictEqual({
            errors: groupUpdateResponseWithErrors.data.groupUpdate.errors,
            scrollOnError: true,
          });
        });
      });
    });
  });
});

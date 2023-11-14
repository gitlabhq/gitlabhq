import VueApollo from 'vue-apollo';
import Vue, { nextTick } from 'vue';

import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import OrganizationSettings from '~/organizations/settings/general/components/organization_settings.vue';
import SettingsBlock from '~/vue_shared/components/settings/settings_block.vue';
import NewEditForm from '~/organizations/shared/components/new_edit_form.vue';
import { FORM_FIELD_NAME, FORM_FIELD_ID } from '~/organizations/shared/constants';
import resolvers from '~/organizations/shared/graphql/resolvers';
import { createAlert, VARIANT_INFO } from '~/alert';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';

Vue.use(VueApollo);
jest.useFakeTimers();
jest.mock('~/alert');

describe('OrganizationSettings', () => {
  let wrapper;
  let mockApollo;

  const defaultProvide = {
    organization: {
      id: 1,
      name: 'GitLab',
    },
  };

  const createComponent = ({ mockResolvers = resolvers } = {}) => {
    mockApollo = createMockApollo([], mockResolvers);

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
        const mockResolvers = {
          Mutation: {
            updateOrganization: jest.fn().mockReturnValueOnce(new Promise(() => {})),
          },
        };

        createComponent({ mockResolvers });

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
        jest.runAllTimers();
        await waitForPromises();
      });

      it('displays info alert', () => {
        expect(createAlert).toHaveBeenCalledWith({
          message: 'Organization was successfully updated.',
          variant: VARIANT_INFO,
        });
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
        await submitForm();
        jest.runAllTimers();
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
  });
});

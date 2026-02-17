import {
  GlForm,
  GlFormGroup,
  GlFormInput,
  GlFormTextarea,
  GlButton,
  GlExperimentBadge,
} from '@gitlab/ui';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { createAlert } from '~/alert';
import { scrollTo } from '~/lib/utils/scroll_utils';
import PageHeading from '~/vue_shared/components/page_heading.vue';
import CreateGranularPersonalAccessTokenForm from '~/personal_access_tokens/components/create_granular_token/create_granular_personal_access_token_form.vue';
import PersonalAccessTokenExpirationDate from '~/personal_access_tokens/components/create_granular_token/personal_access_token_expiration_date.vue';
import PersonalAccessTokenScopeSelector from '~/personal_access_tokens/components/create_granular_token/personal_access_token_scope_selector.vue';
import PersonalAccessTokenNamespaceSelector from '~/personal_access_tokens/components/create_granular_token/personal_access_token_namespace_selector.vue';
import PersonalAccessTokenPermissionsSelector from '~/personal_access_tokens/components/create_granular_token/personal_access_token_permissions_selector.vue';
import CreatedPersonalAccessToken from '~/personal_access_tokens/components/created_personal_access_token.vue';
import createGranularPersonalAccessTokenMutation from '~/personal_access_tokens/graphql/create_granular_personal_access_token.mutation.graphql';
import { MAX_DESCRIPTION_LENGTH } from '~/personal_access_tokens/constants';
import { mockCreateMutationResponse, mockCreateMutationInput } from '../../mock_data';

jest.mock('~/alert');
jest.mock('~/lib/utils/scroll_utils');

Vue.use(VueApollo);

describe('CreateGranularPersonalAccessTokenForm', () => {
  let wrapper;
  let mockApollo;

  const mockMutationHandler = jest.fn().mockResolvedValue(mockCreateMutationResponse);

  const createComponent = ({ mutationHandler = mockMutationHandler, provide = {} } = {}) => {
    mockApollo = createMockApollo([[createGranularPersonalAccessTokenMutation, mutationHandler]]);

    wrapper = shallowMountExtended(CreateGranularPersonalAccessTokenForm, {
      apolloProvider: mockApollo,
      provide: {
        accessTokenMaxDate: '2025-12-31',
        accessTokenTableUrl: '/-/personal_access_tokens',
        ...provide,
      },
    });
  };

  const findForm = () => wrapper.findComponent(GlForm);
  const findPageHeading = () => wrapper.findComponent(PageHeading);

  const findExperimentBadge = () => wrapper.findComponent(GlExperimentBadge);

  const findNameFormGroup = () => wrapper.findAllComponents(GlFormGroup).at(0);
  const findDescriptionFormGroup = () => wrapper.findAllComponents(GlFormGroup).at(1);
  const findNameInput = () => wrapper.findComponent(GlFormInput);
  const findDescriptionTextarea = () => wrapper.findComponent(GlFormTextarea);
  const findExpirationDateComponent = () =>
    wrapper.findComponent(PersonalAccessTokenExpirationDate);

  const findScopeSelectorComponent = () => wrapper.findComponent(PersonalAccessTokenScopeSelector);
  const findNamespaceSelector = () => wrapper.findComponent(PersonalAccessTokenNamespaceSelector);

  const findPermissionsSelectors = () =>
    wrapper.findAllComponents(PersonalAccessTokenPermissionsSelector);
  const findGroupPermissionsSelector = () => findPermissionsSelectors().at(0);
  const findUserPermissionsSelector = () => findPermissionsSelectors().at(1);

  const findCreateButton = () => wrapper.findAllComponents(GlButton).at(0);
  const findCancelButton = () => wrapper.findAllComponents(GlButton).at(1);

  const findCreatedToken = () => wrapper.findComponent(CreatedPersonalAccessToken);

  const fillFormWithValidData = async (
    options = { groupPermissions: true, userPermissions: true },
  ) => {
    findNameInput().vm.$emit('input', mockCreateMutationInput.name);
    findDescriptionTextarea().vm.$emit('input', mockCreateMutationInput.description);
    findExpirationDateComponent().vm.$emit('input', mockCreateMutationInput.expirationDate);

    if (options.groupPermissions) {
      findScopeSelectorComponent().vm.$emit('input', mockCreateMutationInput.group.access);

      await nextTick();

      findNamespaceSelector().vm.$emit('input', mockCreateMutationInput.group.resourceIds);
      findGroupPermissionsSelector().vm.$emit('input', mockCreateMutationInput.group.permissions);
    }

    if (options.userPermissions) {
      findUserPermissionsSelector().vm.$emit('input', mockCreateMutationInput.user.permissions);
    }
  };

  beforeEach(() => {
    createComponent();
  });

  it('renders the page heading', () => {
    expect(findPageHeading().exists()).toBe(true);
    expect(findPageHeading().text()).toContain('Generate fine-grained token');
    expect(findPageHeading().text()).toContain(
      'Fine-grained personal access tokens give you granular control over the specific resources and actions available to the token.',
    );
  });

  it('renders the experiment badge', () => {
    expect(findExperimentBadge().exists()).toBe(true);
    expect(findExperimentBadge().props('type')).toBe('beta');
  });

  describe('form fields', () => {
    it('renders the form container', () => {
      expect(findForm().exists()).toBe(true);
      expect(findForm().classes()).toContain('js-quick-submit');

      expect(findCreatedToken().exists()).toBe(false);
    });

    it('renders the name field with correct label', () => {
      expect(findNameFormGroup().exists()).toBe(true);
      expect(findNameFormGroup().attributes('label')).toBe('Name');
      expect(findNameFormGroup().attributes('label-for')).toBe('token-name');

      expect(findNameInput().exists()).toBe(true);
      expect(findNameInput().attributes('id')).toBe('token-name');
    });

    it('renders the description field with correct label', () => {
      expect(findDescriptionFormGroup().exists()).toBe(true);
      expect(findDescriptionFormGroup().attributes('label')).toBe('Description');
      expect(findDescriptionFormGroup().attributes('label-for')).toBe('token-description');

      expect(findDescriptionTextarea().exists()).toBe(true);
      expect(findDescriptionTextarea().attributes('id')).toBe('token-description');
    });

    it('renders the expiration date component', () => {
      expect(findExpirationDateComponent().exists()).toBe(true);
    });

    it('renders the scope selector component', () => {
      expect(findScopeSelectorComponent().exists()).toBe(true);
    });

    it('renders namespace selector when access is `SELECTED_MEMBERSHIPS`', async () => {
      expect(findNamespaceSelector().exists()).toBe(false);

      await findScopeSelectorComponent().vm.$emit('input', 'SELECTED_MEMBERSHIPS');

      expect(findNamespaceSelector().exists()).toBe(true);
    });

    it('renders permissions selectors for group and user scope', () => {
      expect(findPermissionsSelectors()).toHaveLength(2);

      expect(findGroupPermissionsSelector().props('targetBoundaries')).toEqual([
        'GROUP',
        'PROJECT',
      ]);
      expect(findUserPermissionsSelector().props('targetBoundaries')).toEqual(['USER']);
    });
  });

  describe('form buttons', () => {
    it('renders the cancel button', () => {
      expect(findCancelButton().exists()).toBe(true);
      expect(findCancelButton().text()).toBe('Cancel');
      expect(findCancelButton().attributes('href')).toBe('/-/personal_access_tokens');
    });

    it('renders the create button', () => {
      expect(findCreateButton().exists()).toBe(true);
      expect(findCreateButton().props('variant')).toBe('confirm');
      expect(findCreateButton().text()).toBe('Generate token');
    });
  });

  describe('form validation', () => {
    it('validates name is required', async () => {
      await findCreateButton().vm.$emit('click');

      expect(findNameFormGroup().attributes('invalid-feedback')).toBe('Token name is required.');
    });

    it('validates description is required', async () => {
      await findCreateButton().vm.$emit('click');

      expect(findDescriptionFormGroup().attributes('invalid-feedback')).toBe(
        'Token description is required.',
      );
    });

    it('validates description length', async () => {
      const longDescription = 'a'.repeat(MAX_DESCRIPTION_LENGTH + 1);
      findDescriptionTextarea().vm.$emit('input', longDescription);

      await findCreateButton().vm.$emit('click');

      expect(findDescriptionFormGroup().attributes('invalid-feedback')).toBe(
        'Description is too long (maximum is 255 characters).',
      );
    });

    it('validates expiration date when `accessTokenMaxDate` is provided', async () => {
      await findCreateButton().vm.$emit('click');

      expect(findExpirationDateComponent().props('error')).toBe('Expiration date is required.');
    });

    it('does not validation expiration date when `accessTokenMaxDate` is null', async () => {
      createComponent({ provide: { accessTokenMaxDate: null } });

      await findCreateButton().vm.$emit('click');

      expect(findExpirationDateComponent().props('error')).toBe('');
    });

    it('validates scope is required when group permissions are selected', async () => {
      findGroupPermissionsSelector().vm.$emit('input', mockCreateMutationInput.group.permissions);

      await findCreateButton().vm.$emit('click');

      expect(findScopeSelectorComponent().props('error')).toBe('At least one scope is required.');
    });

    it('validates namespaces are required if access `SELECTED_MEMBERSHIPS`', async () => {
      findScopeSelectorComponent().vm.$emit('input', 'SELECTED_MEMBERSHIPS');
      await findCreateButton().vm.$emit('click');

      expect(findNamespaceSelector().props('error')).toBe(
        'At least one group or project is required.',
      );
    });

    it('validates permissions are required', async () => {
      await findCreateButton().vm.$emit('click');

      expect(findGroupPermissionsSelector().props('error')).toBe(
        'At least one permission is required.',
      );
      expect(findUserPermissionsSelector().props('error')).toBe(
        'At least one permission is required.',
      );
    });
  });

  describe('form submission', () => {
    it('does not submit when form is invalid', async () => {
      await fillFormWithValidData();
      findNameInput().vm.$emit('input', '');

      await findCreateButton().vm.$emit('click');

      expect(mockMutationHandler).not.toHaveBeenCalled();
    });

    it('submits form with correct variables when both group & user permissions are selected', async () => {
      await fillFormWithValidData();
      await findCreateButton().vm.$emit('click');

      expect(mockMutationHandler).toHaveBeenCalledWith({
        input: {
          name: mockCreateMutationInput.name,
          description: mockCreateMutationInput.description,
          expiresAt: mockCreateMutationInput.expirationDate,
          granularScopes: [
            {
              access: mockCreateMutationInput.group.access,
              resourceIds: mockCreateMutationInput.group.resourceIds,
              permissions: mockCreateMutationInput.group.permissions,
            },
            {
              access: mockCreateMutationInput.user.access,
              permissions: mockCreateMutationInput.user.permissions,
            },
          ],
        },
      });
    });

    it('submits form with correct variables when only group permissions are selected', async () => {
      await fillFormWithValidData({ groupPermissions: false, userPermissions: true });
      await findCreateButton().vm.$emit('click');

      expect(mockMutationHandler).toHaveBeenCalledWith({
        input: {
          name: mockCreateMutationInput.name,
          description: mockCreateMutationInput.description,
          expiresAt: mockCreateMutationInput.expirationDate,
          granularScopes: [
            {
              access: mockCreateMutationInput.user.access,
              permissions: mockCreateMutationInput.user.permissions,
            },
          ],
        },
      });
    });

    it('submits form with correct variables when only user permissions are selected', async () => {
      await fillFormWithValidData({ groupPermissions: true, userPermissions: false });
      await findCreateButton().vm.$emit('click');

      expect(mockMutationHandler).toHaveBeenCalledWith({
        input: {
          name: mockCreateMutationInput.name,
          description: mockCreateMutationInput.description,
          expiresAt: mockCreateMutationInput.expirationDate,
          granularScopes: [
            {
              access: mockCreateMutationInput.group.access,
              resourceIds: mockCreateMutationInput.group.resourceIds,
              permissions: mockCreateMutationInput.group.permissions,
            },
          ],
        },
      });
    });

    it('displays the created token and hides the form', async () => {
      await fillFormWithValidData();
      await findCreateButton().vm.$emit('click');

      await waitForPromises();

      expect(findCreatedToken().exists()).toBe(true);
      expect(findCreatedToken().props('value')).toBe(
        mockCreateMutationResponse.data.personalAccessTokenCreate.token,
      );

      expect(findForm().exists()).toBe(false);
    });

    it('displays an error message when mutation returns an error', async () => {
      const errorMutationHandler = jest.fn().mockResolvedValue({
        data: {
          personalAccessTokenCreate: {
            token: null,
            errors: ['Error 1', 'Error 2'],
          },
        },
      });

      createComponent({ mutationHandler: errorMutationHandler });

      await fillFormWithValidData();
      await findCreateButton().vm.$emit('click');
      await waitForPromises();

      expect(createAlert).toHaveBeenCalledWith({
        message: 'Token generation unsuccessful. Please try again.',
        captureError: true,
        error: expect.any(Error),
      });
    });

    it('displays an error message when mutation fails', async () => {
      const errorMutationHandler = jest.fn().mockRejectedValue(new Error('Mutation failed'));
      createComponent({ mutationHandler: errorMutationHandler });

      await fillFormWithValidData();

      await findCreateButton().vm.$emit('click');
      await waitForPromises();

      expect(createAlert).toHaveBeenCalledWith({
        message: 'Token generation unsuccessful. Please try again.',
        captureError: true,
        error: expect.any(Error),
      });

      expect(scrollTo).toHaveBeenCalledWith({ top: 0, behavior: 'smooth' }, wrapper.element);
    });
  });
});

import {
  GlForm,
  GlFormGroup,
  GlFormInput,
  GlFormTextarea,
  GlButton,
  GlExperimentBadge,
  GlLink,
  GlTabs,
  GlSprintf,
  GlLoadingIcon,
} from '@gitlab/ui';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import createMockApollo from 'helpers/mock_apollo_helper';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import setWindowLocation from 'helpers/set_window_location_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { createAlert } from '~/alert';
import { helpPagePath } from '~/helpers/help_page_helper';
import { scrollTo, scrollToElement } from '~/lib/utils/scroll_utils';
import PageHeading from '~/vue_shared/components/page_heading.vue';
import CreateGranularPersonalAccessTokenForm from '~/personal_access_tokens/components/create_granular_token/create_granular_personal_access_token_form.vue';
import PersonalAccessTokenExpirationDate from '~/personal_access_tokens/components/create_granular_token/personal_access_token_expiration_date.vue';
import PersonalAccessTokenScopeSelector from '~/personal_access_tokens/components/create_granular_token/personal_access_token_scope_selector.vue';
import PersonalAccessTokenNamespaceSelector from '~/personal_access_tokens/components/create_granular_token/personal_access_token_namespace_selector.vue';
import PersonalAccessTokenPermissionsSelector from '~/personal_access_tokens/components/create_granular_token/personal_access_token_permissions_selector.vue';
import ConfirmUnsavedChangesDialog from '~/vue_shared/components/confirm_unsaved_changes_dialog.vue';
import CreatedPersonalAccessToken from '~/personal_access_tokens/components/created_personal_access_token.vue';
import createGranularPersonalAccessTokenMutation from '~/personal_access_tokens/graphql/create_granular_personal_access_token.mutation.graphql';
import getAccessTokenPermissions from '~/personal_access_tokens/graphql/get_access_token_permissions.query.graphql';
import getSourcePersonalAccessToken from '~/personal_access_tokens/graphql/get_source_personal_access_token.query.graphql';
import { MAX_NAME_LENGTH, MAX_DESCRIPTION_LENGTH } from '~/personal_access_tokens/constants';
import {
  mockCreateMutationResponse,
  mockCreateMutationInput,
  mockSourceTokenQueryResponse,
  mockGroupScopedTokenQueryResponse,
  mockProjectScopedTokenQueryResponse,
  mockUserScopedTokenQueryResponse,
  mockNullDescriptionTokenQueryResponse,
  mockLegacySourceTokenQueryResponse,
  mockProjects,
  mockGroups,
} from '../../mock_data';

jest.mock('~/alert');
jest.mock('~/lib/utils/scroll_utils');

Vue.use(VueApollo);

describe('CreateGranularPersonalAccessTokenForm', () => {
  let wrapper;
  let mockApollo;

  const mockMutationHandler = jest.fn().mockResolvedValue(mockCreateMutationResponse);
  const mockPermissionsHandler = jest
    .fn()
    .mockResolvedValue({ data: { accessTokenPermissions: [] } });

  const mockSourceTokenHandler = jest.fn().mockResolvedValue(mockGroupScopedTokenQueryResponse);

  const createComponent = ({
    mutationHandler = mockMutationHandler,
    sourceTokenHandler = mockSourceTokenHandler,
    provide = {},
  } = {}) => {
    mockApollo = createMockApollo([
      [createGranularPersonalAccessTokenMutation, mutationHandler],
      [getAccessTokenPermissions, mockPermissionsHandler],
      [getSourcePersonalAccessToken, sourceTokenHandler],
    ]);

    wrapper = shallowMountExtended(CreateGranularPersonalAccessTokenForm, {
      apolloProvider: mockApollo,
      provide: {
        accessTokenMaxDate: '2025-12-31',
        accessTokenTableUrl: '/-/personal_access_tokens',
        ...provide,
      },
      stubs: {
        GlSprintf,
        GlTabs: { template: '<div><slot name="tabs-end" /><slot /></div>' },
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

  const findLink = () => wrapper.findComponent(GlLink);
  const findLinks = () => wrapper.findAllComponents(GlLink);
  const findTabs = () => wrapper.findComponent(GlTabs);

  const findPermissionsSelectors = () =>
    wrapper.findAllComponents(PersonalAccessTokenPermissionsSelector);
  const findGroupPermissionsSelector = () => findPermissionsSelectors().at(0);
  const findUserPermissionsSelector = () => findPermissionsSelectors().at(1);

  const findCreateButton = () => wrapper.findAllComponents(GlButton).at(0);
  const findCancelButton = () => wrapper.findAllComponents(GlButton).at(1);

  const findConfirmDialog = () => wrapper.findComponent(ConfirmUnsavedChangesDialog);
  const findCreatedToken = () => wrapper.findComponent(CreatedPersonalAccessToken);
  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);

  const fillFormWithValidData = async (
    options = { groupPermissions: true, userPermissions: true },
  ) => {
    findNameInput().vm.$emit('input', mockCreateMutationInput.name);
    findDescriptionTextarea().vm.$emit('input', mockCreateMutationInput.description);
    findExpirationDateComponent().vm.$emit('input', mockCreateMutationInput.expirationDate);

    if (options.groupPermissions) {
      findScopeSelectorComponent().vm.$emit('input', mockCreateMutationInput.group.access);

      await nextTick();

      findNamespaceSelector().vm.$emit('input', [mockProjects[0], mockGroups[0]]);
      findGroupPermissionsSelector().vm.$emit('input', mockCreateMutationInput.group.permissions);
    }

    if (options.userPermissions) {
      findUserPermissionsSelector().vm.$emit('input', mockCreateMutationInput.user.permissions);
    }
  };

  const fillAndSubmitForm = async (options) => {
    await fillFormWithValidData(options);
    findCreateButton().vm.$emit('click');
    return waitForPromises();
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
      expect(findNameInput().attributes()).toMatchObject({
        id: 'token-name',
        maxlength: `${MAX_NAME_LENGTH}`,
      });
    });

    it('renders the description field with correct label', () => {
      expect(findDescriptionFormGroup().exists()).toBe(true);
      expect(findDescriptionFormGroup().attributes('label')).toBe('Description');
      expect(findDescriptionFormGroup().attributes('label-for')).toBe('token-description');

      expect(findDescriptionTextarea().exists()).toBe(true);
      expect(findDescriptionTextarea().attributes()).toMatchObject({
        id: 'token-description',
        maxlength: `${MAX_DESCRIPTION_LENGTH}`,
      });
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

    it('displays the add permissions heading and description', () => {
      const text = wrapper.text().replace(/\s+/g, ' ');
      expect(text).toContain('Add resource permissions');
      expect(text).toContain(
        'Add only the minimum resource and permissions needed for your token. Permissions not included in your assigned role have no effect.',
      );

      expect(findLink().attributes('href')).toBe(
        helpPagePath('auth/tokens/fine_grained_access_tokens.md'),
      );
    });

    it('opens the documentation link in a new tab', () => {
      expect(findLink().attributes('target')).toBe('_blank');
    });

    it('displays the public access note with a link to the publicly accessible endpoints docs', () => {
      const text = wrapper.text().replace(/\s+/g, ' ');
      expect(text).toContain(
        'Publicly visible resources are accessible without a permission. See the list of publicly accessible endpoints',
      );

      const publicAccessLink = findLinks().at(1);
      expect(publicAccessLink.attributes('href')).toBe(
        helpPagePath('auth/tokens/fine_grained_access_tokens.md', {
          anchor: 'publicly-accessible-endpoints',
        }),
      );
      expect(publicAccessLink.attributes('target')).toBe('_blank');
    });

    it('renders permissions selectors for group and user scope', () => {
      expect(findTabs().exists()).toBe(true);

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

      expect(findNameFormGroup().attributes('invalid-feedback')).toBe('Add token name.');
    });

    it('validates description is required', async () => {
      await findCreateButton().vm.$emit('click');

      expect(findDescriptionFormGroup().attributes('invalid-feedback')).toBe(
        'Add token description.',
      );
    });

    it('does not validate expiration date when `accessTokenMaxDate` is null', async () => {
      createComponent({ provide: { accessTokenMaxDate: null } });

      await findCreateButton().vm.$emit('click');

      expect(findExpirationDateComponent().props('error')).toBe('');
    });

    it('validates scope is required when group permissions are selected', async () => {
      findGroupPermissionsSelector().vm.$emit('input', mockCreateMutationInput.group.permissions);

      await findCreateButton().vm.$emit('click');

      expect(findScopeSelectorComponent().props('error')).toBe('Set group and project access.');
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
        'Add at least one resource with permissions.',
      );
      expect(findUserPermissionsSelector().props('error')).toBe(
        'Add at least one resource with permissions.',
      );
    });
  });

  describe('unsaved changes dialog', () => {
    it('renders the confirm unsaved changes dialog', () => {
      expect(findConfirmDialog().exists()).toBe(true);
    });

    it('passes hasUnsavedChanges as false when form is pristine', () => {
      expect(findConfirmDialog().props('hasUnsavedChanges')).toBe(false);
    });

    it.each`
      field               | action
      ${'name'}           | ${() => findNameInput().vm.$emit('input', 'test')}
      ${'description'}    | ${() => findDescriptionTextarea().vm.$emit('input', 'test')}
      ${'expirationDate'} | ${() => findExpirationDateComponent().vm.$emit('input', new Date())}
      ${'access'}         | ${() => findScopeSelectorComponent().vm.$emit('input', 'ALL_MEMBERSHIPS')}
    `('passes hasUnsavedChanges as true when $field is changed', async ({ action }) => {
      action();
      await nextTick();

      expect(findConfirmDialog().props('hasUnsavedChanges')).toBe(true);
    });

    it('passes hasUnsavedChanges as true when permissions are changed', async () => {
      findGroupPermissionsSelector().vm.$emit('input', ['read_project']);
      await nextTick();

      expect(findConfirmDialog().props('hasUnsavedChanges')).toBe(true);
    });
  });

  describe('form submission', () => {
    it('does not submit when form is invalid', async () => {
      await fillFormWithValidData();
      findNameInput().vm.$emit('input', '');

      await findCreateButton().vm.$emit('click');

      expect(mockMutationHandler).not.toHaveBeenCalled();
    });

    it('scrolls to the first invalid field when validation fails', async () => {
      findNameFormGroup().element.classList.add('invalid-feedback');

      await findCreateButton().vm.$emit('click');
      await nextTick();

      expect(scrollToElement).toHaveBeenCalledWith(findNameFormGroup().element, {
        behavior: 'smooth',
        offset: -100,
      });
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
      await fillAndSubmitForm({ groupPermissions: false, userPermissions: true });

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
      await fillAndSubmitForm({ groupPermissions: true, userPermissions: false });

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
      await fillAndSubmitForm();

      expect(findCreatedToken().props()).toMatchObject({
        token: 'xx',
        href: '/-/personal_access_tokens',
      });

      expect(findForm().exists()).toBe(false);
    });

    it('resets isFormDirty after successful submission', async () => {
      await fillFormWithValidData();
      await nextTick();

      expect(findConfirmDialog().props('hasUnsavedChanges')).toBe(true);

      await findCreateButton().vm.$emit('click');
      await waitForPromises();

      expect(findConfirmDialog().props('hasUnsavedChanges')).toBe(false);
    });

    it('displays an error message when mutation returns an error', async () => {
      const errorMutationHandler = jest.fn().mockResolvedValue({
        data: {
          personalAccessTokenCreate: {
            token: null,
            errors: ['Error 1'],
          },
        },
      });

      createComponent({ mutationHandler: errorMutationHandler });
      await fillAndSubmitForm();

      expect(createAlert).toHaveBeenCalledWith({
        message: 'Error 1',
        captureError: true,
        error: expect.any(Error),
      });
    });

    it('displays an error message when mutation call fails', async () => {
      const error = new Error('Mutation call failed');
      createComponent({ mutationHandler: jest.fn().mockRejectedValue(error) });
      await fillAndSubmitForm();

      expect(createAlert).toHaveBeenCalledWith({
        message: 'Token generation unsuccessful. Please try again.',
        captureError: true,
        error,
      });

      expect(scrollTo).toHaveBeenCalledWith({ top: 0, behavior: 'smooth' }, wrapper.element);
    });
  });

  describe('duplicating a token', () => {
    beforeEach(() => {
      window.gon = { current_user_id: 42 };
      setWindowLocation('?source_token_id=1');
    });

    it('shows a loading spinner while the source token query is in progress', () => {
      createComponent();

      expect(findLoadingIcon().exists()).toBe(true);
      expect(findForm().exists()).toBe(false);
    });

    it('hides the loading spinner and shows the form after the query completes', async () => {
      createComponent();
      await waitForPromises();

      expect(findLoadingIcon().exists()).toBe(false);
      expect(findForm().exists()).toBe(true);
    });

    it('fetches the source token with the correct variables', async () => {
      createComponent();
      await waitForPromises();

      expect(mockSourceTokenHandler).toHaveBeenCalledWith({
        userId: 'gid://gitlab/User/42',
        id: 'gid://gitlab/PersonalAccessToken/1',
      });
    });

    it('pre-populates name, description, and access from the fetched token', async () => {
      createComponent();
      await waitForPromises();

      expect(findNameInput().attributes('value')).toBe('Token 1 (copy)');
      expect(findDescriptionTextarea().attributes('value')).toBe('Test token 1');
      expect(findScopeSelectorComponent().props('value')).toBe('SELECTED_MEMBERSHIPS');
    });

    it('passes prefill permissions to the correct permission selectors by boundary', async () => {
      createComponent();
      await waitForPromises();

      expect(findGroupPermissionsSelector().props('value')).toEqual([
        'read_project',
        'write_project',
        'read_repository',
        'read_contributed_project',
      ]);

      expect(findUserPermissionsSelector().props('value')).toEqual([]);
    });

    it('pre-populates namespace selector from the fetched token scopes', async () => {
      createComponent();
      await waitForPromises();

      expect(findNamespaceSelector().exists()).toBe(true);

      expect(findNamespaceSelector().props('value')).toEqual([
        expect.objectContaining({ id: 'gid://gitlab/Group/1', fullPath: 'my-group' }),
      ]);
    });

    it('uses the project object (not namespace) when pre-populating project scopes', async () => {
      createComponent({
        sourceTokenHandler: jest.fn().mockResolvedValue(mockProjectScopedTokenQueryResponse),
      });
      await waitForPromises();

      expect(findNamespaceSelector().props('value')).toEqual([
        expect.objectContaining({
          id: 'gid://gitlab/Project/10',
          fullPath: 'my-group/my-project',
          __typename: 'Project',
        }),
      ]);
    });

    it('handles user-scope-only source token without setting access or namespaces', async () => {
      createComponent({
        sourceTokenHandler: jest.fn().mockResolvedValue(mockUserScopedTokenQueryResponse),
      });
      await waitForPromises();

      expect(findNameInput().attributes('value')).toBe('User Only Token (copy)');
      expect(findDescriptionTextarea().attributes('value')).toBe('A user-scoped token');
      expect(findNamespaceSelector().exists()).toBe(false);
      expect(findGroupPermissionsSelector().props('value')).toEqual([]);
      expect(findUserPermissionsSelector().props('value')).toEqual([
        'read_user',
        'read_contributed_project',
      ]);
    });

    it('sets description to empty string when source token has null description', async () => {
      createComponent({
        sourceTokenHandler: jest.fn().mockResolvedValue(mockNullDescriptionTokenQueryResponse),
      });

      await waitForPromises();

      expect(findDescriptionTextarea().attributes('value')).toBe('');
    });

    it('does not pre-populate the form when source token is not granular', async () => {
      createComponent({
        sourceTokenHandler: jest.fn().mockResolvedValue(mockLegacySourceTokenQueryResponse),
      });
      await waitForPromises();

      expect(findNameInput().attributes('value')).toBe('');
      expect(findDescriptionTextarea().attributes('value')).toBe('');
      expect(findScopeSelectorComponent().props('value')).toBeNull();
    });

    it('shows an alert when the source token fetch fails', async () => {
      const error = new Error('GraphQL error');
      createComponent({ sourceTokenHandler: jest.fn().mockRejectedValue(error) });
      await waitForPromises();

      expect(createAlert).toHaveBeenCalledWith(
        expect.objectContaining({
          message: 'Failed to load source token. Please fill in the form manually.',
          captureError: true,
          error,
        }),
      );
    });

    it('does not fetch source token when source_token_id is absent', async () => {
      setWindowLocation('?');
      const sourceTokenHandler = jest.fn().mockResolvedValue(mockSourceTokenQueryResponse);
      createComponent({ sourceTokenHandler });
      await waitForPromises();

      expect(sourceTokenHandler).not.toHaveBeenCalled();
    });

    it('splits permissions correctly for tokens with both namespace and user scopes', async () => {
      createComponent({
        sourceTokenHandler: jest.fn().mockResolvedValue(mockSourceTokenQueryResponse),
      });

      await waitForPromises();

      expect(findGroupPermissionsSelector().props('value')).toEqual(['read_project']);

      expect(findUserPermissionsSelector().props('value')).toEqual([
        'read_user',
        'read_contributed_project',
      ]);

      expect(findNamespaceSelector().props('value')).toEqual([
        expect.objectContaining({ id: 'gid://gitlab/Project/10' }),
      ]);
    });
  });
});

import { GlForm, GlFormGroup, GlFormInput, GlFormTextarea, GlButton } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import PageHeading from '~/vue_shared/components/page_heading.vue';
import CreateGranularPersonalAccessTokenForm from '~/personal_access_tokens/components/create_granular_token/create_granular_personal_access_token_form.vue';
import PersonalAccessTokenExpirationDate from '~/personal_access_tokens/components/create_granular_token/personal_access_token_expiration_date.vue';
import PersonalAccessTokenScopeSelector from '~/personal_access_tokens/components/create_granular_token/personal_access_token_scope_selector.vue';
import { MAX_DESCRIPTION_LENGTH } from '~/personal_access_tokens/constants';

describe('CreateGranularPersonalAccessTokenForm', () => {
  let wrapper;

  const createComponent = (provide = {}) => {
    wrapper = shallowMountExtended(CreateGranularPersonalAccessTokenForm, {
      provide: {
        accessTokenMaxDate: '2025-12-31',
        ...provide,
      },
    });
  };

  const findForm = () => wrapper.findComponent(GlForm);
  const findPageHeading = () => wrapper.findComponent(PageHeading);
  const findNameFormGroup = () => wrapper.findAllComponents(GlFormGroup).at(0);
  const findDescriptionFormGroup = () => wrapper.findAllComponents(GlFormGroup).at(1);
  const findNameInput = () => wrapper.findComponent(GlFormInput);
  const findDescriptionTextarea = () => wrapper.findComponent(GlFormTextarea);
  const findExpirationDateComponent = () =>
    wrapper.findComponent(PersonalAccessTokenExpirationDate);
  const findScopeSelectorComponent = () => wrapper.findComponent(PersonalAccessTokenScopeSelector);
  const findCancelButton = () => wrapper.findAllComponents(GlButton).at(0);
  const findCreateButton = () => wrapper.findAllComponents(GlButton).at(1);

  beforeEach(() => {
    createComponent();
  });

  it('renders the page heading', () => {
    expect(findPageHeading().exists()).toBe(true);
    expect(findPageHeading().props('heading')).toBe('Generate fine-grained token');
  });

  describe('form fields', () => {
    it('renders the form container', () => {
      expect(findForm().exists()).toBe(true);
      expect(findForm().classes()).toContain('js-quick-submit');
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
  });

  describe('form buttons', () => {
    it('renders the cancel button', () => {
      expect(findCancelButton().exists()).toBe(true);
      expect(findCancelButton().text()).toBe('Cancel');
    });

    it('renders the create button', () => {
      expect(findCreateButton().exists()).toBe(true);
      expect(findCreateButton().props('variant')).toBe('confirm');
      expect(findCreateButton().text()).toBe('Create token');
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
      createComponent({ accessTokenMaxDate: null });

      await findCreateButton().vm.$emit('click');

      expect(findExpirationDateComponent().props('error')).toBe('');
    });

    it('validates scope is required', async () => {
      await findCreateButton().vm.$emit('click');

      expect(findScopeSelectorComponent().props('error')).toBe('At least one scope is required.');
    });
  });
});

import { GlFormInput, GlFormTextarea, GlButton } from '@gitlab/ui';
import { nextTick } from 'vue';
import { shallowMountExtended, mountExtended } from 'helpers/vue_test_utils_helper';
import ProjectGeneralSettings from '~/projects/settings/components/project_general_settings.vue';
import AvatarUploadDropzone from '~/organizations/shared/components/avatar_upload_dropzone.vue';
import TopicsTokenSelector from '~/projects/settings/topics/components/topics_token_selector.vue';

jest.mock('~/lib/utils/csrf', () => ({
  token: 'mock-csrf-token',
}));

// Explicit stub so the async `ee_component` import behaves the same in EE and
// FOSS test runs.
const RepositorySizeLimitFieldStub = {
  name: 'RepositorySizeLimitField',
  props: ['value', 'helpText'],
  template: '<div data-testid="repository-size-limit-field"></div>',
};

describe('ProjectGeneralSettings', () => {
  let wrapper;

  const defaultProps = {
    projectId: '1',
    projectName: 'Test Project',
    projectDescription: 'Test description',
    projectAvatarUrl: 'https://example.com/avatar.png',
    projectAvatarRemovable: true,
    projectTopics: [
      { id: 0, name: 'javascript' },
      { id: 1, name: 'vue' },
    ],
    maxDescriptionLength: 2000,
    formAction: '/projects/test-project',
    organizationId: '1',
    canEditRepositorySizeLimit: false,
    repositorySizeLimitValue: null,
    repositorySizeLimitHelpText: '',
    showRepositorySizeLimitCta: false,
  };

  const createComponent = (props = {}) => {
    wrapper = shallowMountExtended(ProjectGeneralSettings, {
      propsData: {
        ...defaultProps,
        ...props,
      },
      stubs: {
        RepositorySizeLimitField: RepositorySizeLimitFieldStub,
      },
    });
  };

  // Full mount to assert rendered output (e.g. the character counter), with
  // the heavy children stubbed out.
  const createFullComponent = (props = {}) => {
    wrapper = mountExtended(ProjectGeneralSettings, {
      propsData: {
        ...defaultProps,
        ...props,
      },
      stubs: {
        AvatarUploadDropzone: true,
        TopicsTokenSelector: true,
        RepositorySizeLimitField: RepositorySizeLimitFieldStub,
      },
    });
  };

  const findProjectNameInput = () => wrapper.findComponent(GlFormInput);
  const findProjectDescriptionTextarea = () => wrapper.findComponent(GlFormTextarea);
  const findAvatarUploadDropzone = () => wrapper.findComponent(AvatarUploadDropzone);
  const findTopicsTokenSelector = () => wrapper.findComponent(TopicsTokenSelector);
  const findSaveButton = () => wrapper.findComponent(GlButton);
  const findRepositorySizeLimitField = () => wrapper.findByTestId('repository-size-limit-field');
  const findEeRepositorySizeLimitField = () => wrapper.findComponent(RepositorySizeLimitFieldStub);

  describe('rendering', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders form with correct attributes', () => {
      const form = wrapper.find('form');
      expect(form.attributes('action')).toBe('/projects/test-project');
      expect(form.attributes('method')).toBe('post');
      expect(form.classes()).toContain('js-general-settings-form');
    });

    it('renders hidden form fields for Rails', () => {
      const hiddenInputs = wrapper.findAll('input[type="hidden"]');
      const hiddenInputsData = hiddenInputs.wrappers.map((w) => ({
        name: w.attributes('name'),
        value: w.attributes('value'),
      }));

      expect(hiddenInputsData).toEqual(
        expect.arrayContaining([
          { name: 'authenticity_token', value: 'mock-csrf-token' },
          { name: '_method', value: 'put' },
          { name: 'update_section', value: 'js-general-settings' },
          { name: 'project[topics]', value: 'javascript, vue' },
        ]),
      );
    });

    it('renders the project name input with correct value', () => {
      expect(findProjectNameInput().attributes('value')).toBe('Test Project');
    });

    it('renders the project ID field as readonly and not disabled so it stays copyable', () => {
      const idInput = wrapper.findAllComponents(GlFormInput).at(1);
      expect(idInput.attributes('value')).toBe('1');
      expect(idInput.attributes('readonly')).toBeDefined();
      expect(idInput.attributes('disabled')).toBeUndefined();
    });

    it('renders the project description textarea with correct value', () => {
      expect(findProjectDescriptionTextarea().attributes('value')).toBe('Test description');
    });

    it('renders the avatar upload dropzone with correct props', () => {
      const avatarDropzone = findAvatarUploadDropzone();
      expect(avatarDropzone.exists()).toBe(true);
      expect(avatarDropzone.props('value')).toBe('https://example.com/avatar.png');
      expect(avatarDropzone.props('label')).toBe('Project avatar');
      expect(avatarDropzone.props('inputFieldName')).toBe('project[avatar]');
    });

    it('renders the topics token selector with correct props', () => {
      const topicsSelector = findTopicsTokenSelector();
      expect(topicsSelector.exists()).toBe(true);
      expect(topicsSelector.props('selected')).toEqual([
        { id: 0, name: 'javascript' },
        { id: 1, name: 'vue' },
      ]);
      expect(topicsSelector.props('organizationId')).toBe('1');
    });

    it('renders the save button', () => {
      expect(findSaveButton().text()).toBe('Save changes');
    });

    it('renders hidden input for avatar removal when avatar is removed', async () => {
      createComponent();
      findAvatarUploadDropzone().vm.$emit('input', null);
      await nextTick();

      const avatarRemovalInput = wrapper.find('input[name="project[avatar]"][type="hidden"]');
      expect(avatarRemovalInput.exists()).toBe(true);
      expect(avatarRemovalInput.attributes('value')).toBe('');
    });

    it('clears the dropzone input field name while an avatar removal is pending', async () => {
      createComponent();
      expect(findAvatarUploadDropzone().props('inputFieldName')).toBe('project[avatar]');

      findAvatarUploadDropzone().vm.$emit('input', null);
      await nextTick();

      // Defence in depth: an empty file input part carries no filename and is
      // dropped by Rack before Rails sees it, so it cannot override the hidden
      // removal field. Unnaming it makes that independent of middleware
      // behavior.
      expect(findAvatarUploadDropzone().props('inputFieldName')).toBe('');
    });
  });

  describe('character counter', () => {
    it('renders the remaining character count when under the limit', () => {
      // 'Test description' is 16 characters, so 2000 - 16 = 1984 remain.
      createFullComponent();

      expect(wrapper.text()).toContain('1984 characters remaining');
    });

    it('renders the over-limit character count when the limit is exceeded', () => {
      // Legacy descriptions can exceed the limit; the counter must surface it.
      createFullComponent({ projectDescription: 'a'.repeat(2100) });

      expect(wrapper.text()).toContain('100 characters over limit');
    });

    it('is integrated with GlFormTextarea character-count-limit without truncating input', () => {
      createComponent();
      const textarea = findProjectDescriptionTextarea();

      expect(textarea.props('characterCountLimit')).toBe(2000);
      // No maxlength: it would silently truncate pasted text and hide
      // over-limit legacy descriptions from the user.
      expect(textarea.attributes('maxlength')).toBeUndefined();
    });

    it('disables save button when description is over limit', async () => {
      const longDescription = 'a'.repeat(2100);
      createComponent({ projectDescription: longDescription });

      // Change a field to make form dirty
      findProjectNameInput().vm.$emit('input', 'Changed Name');
      await nextTick();

      expect(findSaveButton().props('disabled')).toBe(true);
    });
  });

  describe('avatar upload', () => {
    it('updates avatar when file is selected', async () => {
      createComponent();
      const mockFile = new File(['avatar'], 'avatar.png', { type: 'image/png' });
      const avatarDropzone = findAvatarUploadDropzone();

      avatarDropzone.vm.$emit('input', mockFile);
      await nextTick();

      // Avatar is updated in component state
      expect(findAvatarUploadDropzone().props('value')).toBe(mockFile);
    });

    it('sets avatar to null when the persisted avatar is removed', async () => {
      createComponent();
      const avatarDropzone = findAvatarUploadDropzone();

      avatarDropzone.vm.$emit('input', null);
      await nextTick();

      // Avatar is cleared in component state
      expect(findAvatarUploadDropzone().props('value')).toBe(null);
    });

    it('restores the persisted avatar when a staged file is discarded', async () => {
      createComponent();
      const mockFile = new File(['avatar'], 'avatar.png', { type: 'image/png' });
      const avatarDropzone = findAvatarUploadDropzone();

      avatarDropzone.vm.$emit('input', mockFile);
      await nextTick();
      avatarDropzone.vm.$emit('input', null);
      await nextTick();

      // Discarding the staged file is not a removal of the persisted avatar
      expect(findAvatarUploadDropzone().props('value')).toBe(defaultProps.projectAvatarUrl);
      expect(wrapper.find('input[name="project[avatar]"][type="hidden"]').exists()).toBe(false);
      expect(findSaveButton().props('disabled')).toBe(true);
    });

    it('keeps the form clean when a staged file is discarded on a project without an avatar', async () => {
      createComponent({ projectAvatarUrl: '', projectAvatarRemovable: false });
      const mockFile = new File(['avatar'], 'avatar.png', { type: 'image/png' });
      const avatarDropzone = findAvatarUploadDropzone();

      avatarDropzone.vm.$emit('input', mockFile);
      await nextTick();
      avatarDropzone.vm.$emit('input', null);
      await nextTick();

      expect(findAvatarUploadDropzone().props('value')).toBe('');
      expect(wrapper.find('input[name="project[avatar]"][type="hidden"]').exists()).toBe(false);
      expect(findSaveButton().props('disabled')).toBe(true);
    });
  });

  describe('classification label field', () => {
    const findClassificationLabelField = () => wrapper.findByTestId('classification-label-field');

    it('does not render when external authorization is not enabled', () => {
      createComponent({ externalAuthorizationEnabled: false });

      expect(findClassificationLabelField().exists()).toBe(false);
    });

    it('renders when external authorization is enabled', () => {
      createComponent({
        externalAuthorizationEnabled: true,
        externalAuthorizationClassificationLabel: 'confidential',
      });

      const field = findClassificationLabelField();
      expect(field.exists()).toBe(true);
      expect(field.attributes('value')).toBe('confidential');
    });

    it('updates classification label when value changes', async () => {
      createComponent({
        externalAuthorizationEnabled: true,
        externalAuthorizationClassificationLabel: 'confidential',
      });

      const input = findClassificationLabelField().findComponent(GlFormInput);
      input.vm.$emit('input', 'secret');
      await nextTick();

      expect(input.props('value')).toBe('secret');
    });

    it('receives help text prop when provided', () => {
      const helpText = 'Classification label help text <a href="#">Learn more</a>';
      createComponent({
        externalAuthorizationEnabled: true,
        externalAuthorizationHelpText: helpText,
      });

      expect(wrapper.props('externalAuthorizationHelpText')).toBe(helpText);
    });
  });

  describe('topics handling', () => {
    it('updates topics when token selector changes', async () => {
      createComponent();
      const newTopics = [
        { id: 0, name: 'javascript' },
        { id: 1, name: 'vue' },
        { id: 2, name: 'testing' },
      ];

      findTopicsTokenSelector().vm.$emit('update', newTopics);
      await nextTick();

      // Topics are updated in component state
      expect(findTopicsTokenSelector().props('selected')).toEqual(newTopics);
    });

    it('updates hidden topics input when topics change', async () => {
      createComponent();
      const newTopics = [
        { id: 0, name: 'javascript' },
        { id: 1, name: 'vue' },
        { id: 2, name: 'testing' },
      ];

      findTopicsTokenSelector().vm.$emit('update', newTopics);
      await nextTick();

      const topicsInput = wrapper.find('input[name="project[topics]"]');
      expect(topicsInput.attributes('value')).toBe('javascript, vue, testing');
    });
  });

  describe('repository size limit field', () => {
    it('does not render when user cannot edit repository size limit', () => {
      createComponent({ canEditRepositorySizeLimit: false, showRepositorySizeLimitCta: false });

      expect(findRepositorySizeLimitField().exists()).toBe(false);
    });

    it('renders the EE field when user can edit repository size limit', () => {
      createComponent({ canEditRepositorySizeLimit: true, repositorySizeLimitValue: 100 });

      expect(findEeRepositorySizeLimitField().props('value')).toBe(100);
    });

    it('renders the disabled CTA field when CTA should be shown', () => {
      createComponent({ canEditRepositorySizeLimit: false, showRepositorySizeLimitCta: true });

      const field = findRepositorySizeLimitField();
      expect(field.exists()).toBe(true);
      expect(findEeRepositorySizeLimitField().exists()).toBe(false);
    });

    it('passes the help text to the EE field', () => {
      const helpText = 'Repository size limit help <a href="#">Learn more</a>';
      createComponent({
        canEditRepositorySizeLimit: true,
        repositorySizeLimitValue: 100,
        repositorySizeLimitHelpText: helpText,
      });

      expect(findEeRepositorySizeLimitField().props('helpText')).toBe(helpText);
    });

    it('updates repository size limit when value changes', async () => {
      createComponent({ canEditRepositorySizeLimit: true, repositorySizeLimitValue: 100 });

      findEeRepositorySizeLimitField().vm.$emit('input', 200);
      await nextTick();

      expect(findEeRepositorySizeLimitField().props('value')).toBe(200);
    });
  });

  describe('form submission', () => {
    it('shows "Saving changes" text and sets loading state when submitting', async () => {
      createComponent();
      const saveButton = findSaveButton();

      // Make form dirty so it can be submitted
      findProjectNameInput().vm.$emit('input', 'Changed Name');
      await nextTick();

      const form = wrapper.find('form');
      const submitEvent = new Event('submit', { cancelable: true, bubbles: true });
      form.element.dispatchEvent(submitEvent);
      await nextTick();

      expect(saveButton.text()).toBe('Saving changes');
      expect(saveButton.props('loading')).toBe(true);
      expect(saveButton.props('disabled')).toBe(true);
    });

    it('allows form to submit naturally when valid', async () => {
      createComponent();

      // Make form dirty
      findProjectNameInput().vm.$emit('input', 'Changed Name');
      await nextTick();

      const form = wrapper.find('form');
      const submitEvent = new Event('submit', { cancelable: true, bubbles: true });
      const preventDefaultSpy = jest.spyOn(submitEvent, 'preventDefault');

      form.element.dispatchEvent(submitEvent);
      await nextTick();

      // Form submission should NOT be prevented for valid submissions
      expect(preventDefaultSpy).not.toHaveBeenCalled();
    });
  });

  describe('form validation', () => {
    it('prevents submission when description is over limit', async () => {
      const longDescription = 'a'.repeat(2100);
      createComponent({ projectDescription: longDescription });
      await nextTick();

      const form = wrapper.find('form');
      const submitEvent = new Event('submit', { cancelable: true, bubbles: true });
      const preventDefaultSpy = jest.spyOn(submitEvent, 'preventDefault');

      form.element.dispatchEvent(submitEvent);
      await nextTick();

      // Form submission should be prevented when description is over limit
      expect(preventDefaultSpy).toHaveBeenCalled();
    });

    it('allows submission when description is at the limit', async () => {
      const exactLimitDescription = 'a'.repeat(2000);
      createComponent({ projectDescription: exactLimitDescription });

      // Make form dirty
      findProjectNameInput().vm.$emit('input', 'Changed Name');
      await nextTick();

      const form = wrapper.find('form');
      const submitEvent = new Event('submit', { cancelable: true, bubbles: true });
      const preventDefaultSpy = jest.spyOn(submitEvent, 'preventDefault');

      form.element.dispatchEvent(submitEvent);
      await nextTick();

      // Form submission should NOT be prevented
      expect(preventDefaultSpy).not.toHaveBeenCalled();
    });
  });

  describe('dirty form detection', () => {
    it('disables save button when form is not dirty', () => {
      createComponent();

      expect(findSaveButton().props('disabled')).toBe(true);
    });

    it('enables save button when project name changes', async () => {
      createComponent();
      findProjectNameInput().vm.$emit('input', 'New Project Name');
      await nextTick();

      expect(findSaveButton().props('disabled')).toBe(false);
    });

    it('enables save button when description changes', async () => {
      createComponent();
      findProjectDescriptionTextarea().vm.$emit('input', 'New description');
      await nextTick();

      expect(findSaveButton().props('disabled')).toBe(false);
    });

    it('enables save button when avatar is uploaded', async () => {
      createComponent();
      const mockFile = new File(['avatar'], 'avatar.png', { type: 'image/png' });
      findAvatarUploadDropzone().vm.$emit('input', mockFile);
      await nextTick();

      expect(findSaveButton().props('disabled')).toBe(false);
    });

    it('enables save button when avatar is removed', async () => {
      createComponent();
      findAvatarUploadDropzone().vm.$emit('input', null);
      await nextTick();

      expect(findSaveButton().props('disabled')).toBe(false);
    });

    it('enables save button when topics change', async () => {
      createComponent();
      const newTopics = [
        { id: 0, name: 'javascript' },
        { id: 1, name: 'vue' },
        { id: 2, name: 'testing' },
      ];
      findTopicsTokenSelector().vm.$emit('update', newTopics);
      await nextTick();

      expect(findSaveButton().props('disabled')).toBe(false);
    });

    it('enables save button when repository size limit changes', async () => {
      createComponent({ canEditRepositorySizeLimit: true, repositorySizeLimitValue: 100 });
      findEeRepositorySizeLimitField().vm.$emit('input', 200);
      await nextTick();

      expect(findSaveButton().props('disabled')).toBe(false);
    });

    it('enables save button when classification label changes', async () => {
      createComponent({
        externalAuthorizationEnabled: true,
        externalAuthorizationClassificationLabel: 'confidential',
      });
      const input = wrapper.findByTestId('classification-label-field').findComponent(GlFormInput);
      input.vm.$emit('input', 'secret');
      await nextTick();

      expect(findSaveButton().props('disabled')).toBe(false);
    });

    it('disables save button when fields are reverted to original values', async () => {
      createComponent();

      // Change name
      findProjectNameInput().vm.$emit('input', 'New Name');
      await nextTick();
      expect(findSaveButton().props('disabled')).toBe(false);

      // Revert to original
      findProjectNameInput().vm.$emit('input', 'Test Project');
      await nextTick();
      expect(findSaveButton().props('disabled')).toBe(true);
    });
  });

  describe('data binding', () => {
    it('updates component data when project name input changes', async () => {
      createComponent();
      const nameInput = findProjectNameInput();

      nameInput.vm.$emit('input', 'Updated Project Name');
      await nextTick();

      // Input value is updated
      expect(nameInput.props('value')).toBe('Updated Project Name');
    });

    it('updates component data when description textarea changes', async () => {
      createComponent();
      const descriptionTextarea = findProjectDescriptionTextarea();

      descriptionTextarea.vm.$emit('input', 'Updated description');
      await nextTick();

      // Textarea value is updated
      expect(descriptionTextarea.props('value')).toBe('Updated description');
    });
  });
});

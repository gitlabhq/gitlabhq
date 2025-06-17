import { nextTick } from 'vue';
import { GlAnimatedUploadIcon, GlFormInput } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import importFromGitlabExportApp from '~/import/gitlab_project/import_from_gitlab_export_app.vue';
import MultiStepFormTemplate from '~/vue_shared/components/multi_step_form_template.vue';

jest.mock('~/lib/utils/csrf', () => ({ token: 'mock-csrf-token' }));

describe('Import from GitLab export file app', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = shallowMountExtended(importFromGitlabExportApp, {
      propsData: {
        backButtonPath: '/projects/new#import_project',
        namespaceFullPath: 'root',
        namespaceId: '1',
        rootPath: '/',
        importGitlabProjectPath: 'import/path',
      },
      stubs: {
        GlFormInput,
      },
    });
  };

  beforeEach(() => {
    createComponent();
  });

  const findMultiStepForm = () => wrapper.findComponent(MultiStepFormTemplate);
  const findForm = () => wrapper.find('form');
  const findProjectNameInput = () => wrapper.findByTestId('project-name');
  const findProjectSlugInput = () => wrapper.findByTestId('project-slug');
  const findDropzoneButton = () => wrapper.findByTestId('dropzone-button');
  const findDropzoneInput = () => wrapper.findByTestId('dropzone-input');
  const findAnimatedUploadIcon = () => wrapper.findComponent(GlAnimatedUploadIcon);
  const findBackButton = () => wrapper.findByTestId('back-button');
  const findNextButton = () => wrapper.findByTestId('next-button');

  const setProjectName = async (projectName) => {
    await findProjectNameInput().setValue(projectName);
    await findProjectNameInput().trigger('blur');

    await nextTick();
  };

  const uploadFile = async () => {
    const file = new File(['foo'], 'foo.gz', { type: 'application/gzip', size: 1024 });
    Object.defineProperty(findDropzoneInput().element, 'files', { value: [file] });
    findDropzoneInput().trigger('change');

    await nextTick();
  };

  describe('form', () => {
    it('renders the multi step form correctly', () => {
      expect(findMultiStepForm().props()).toMatchObject({
        currentStep: 3,
        stepsTotal: 3,
      });
    });

    it('renders the form element correctly', () => {
      const form = findForm();

      expect(form.attributes('action')).toBe('import/path');
      expect(form.find('input[type=hidden][name=authenticity_token]').attributes('value')).toBe(
        'mock-csrf-token',
      );
    });

    it('does not submit the form without requried fields', () => {
      const submitSpy = jest.spyOn(findForm().element, 'submit');

      findForm().trigger('submit');
      expect(submitSpy).not.toHaveBeenCalled();
    });

    it('submits the form with valid form data', async () => {
      const submitSpy = jest.spyOn(findForm().element, 'submit');

      await setProjectName('test project');
      uploadFile();
      await nextTick();

      findForm().trigger('submit');

      expect(submitSpy).toHaveBeenCalledWith();
    });
  });

  describe('validation', () => {
    it('shows an error message when project name is cleared', async () => {
      await setProjectName('');

      const formGroup = wrapper.findByTestId('project-name-form-group');
      expect(formGroup.vm.$attrs['invalid-feedback']).toBe('Please enter a valid project name.');
    });

    it('shows an error message when project name starts with invalid characters', async () => {
      await setProjectName('#test');

      const formGroup = wrapper.findByTestId('project-name-form-group');
      expect(formGroup.vm.$attrs['invalid-feedback']).toBe(
        'Project name must start with a letter, digit, emoji, or underscore.',
      );
    });

    it('shows an error message when project name contains invalid characters', async () => {
      await setProjectName('test?');

      const formGroup = wrapper.findByTestId('project-name-form-group');
      expect(formGroup.vm.$attrs['invalid-feedback']).toBe(
        'Project name can contain only lowercase or uppercase letters, digits, emoji, spaces, dots, underscores, dashes, or pluses.',
      );
    });

    it('shows an error message when there are no file uploaded', async () => {
      findForm().trigger('submit');
      await nextTick();

      const formGroup = wrapper.findByTestId('project-file-form-group');
      expect(formGroup.vm.$attrs['invalid-feedback']).toBe(
        'Please upload a valid GitLab project export file.',
      );
    });
  });

  describe('project slug', () => {
    it('updates the project slug appropriately when updating project name', async () => {
      await setProjectName('test project');

      expect(findProjectSlugInput().props('value')).toBe('test-project');
    });
  });

  describe('drop zone', () => {
    it('renders a drop zone', () => {
      expect(findDropzoneInput().exists()).toBe(true);
      expect(findDropzoneButton().text()).toBe('Drop or upload file to attach');
      expect(findAnimatedUploadIcon().exists()).toBe(true);
    });

    it('uploads a file', async () => {
      await uploadFile();

      expect(findDropzoneButton().text()).toContain('foo.gz');
      expect(findAnimatedUploadIcon().exists()).toBe(false);
    });
  });

  describe('back button', () => {
    it('renders a back button', () => {
      expect(findBackButton().attributes('href')).toBe('/projects/new#import_project');
    });
  });

  describe('next button', () => {
    it('renders a next button', () => {
      expect(findNextButton().attributes('type')).toBe('submit');
    });
  });
});

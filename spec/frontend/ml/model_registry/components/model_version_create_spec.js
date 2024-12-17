import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { GlAlert } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import { visitUrl, visitUrlWithAlerts } from '~/lib/utils/url_utility';
import ModelVersionCreate from '~/ml/model_registry/components/model_version_create.vue';
import ImportArtifactZone from '~/ml/model_registry/components/import_artifact_zone.vue';
import PageHeading from '~/vue_shared/components/page_heading.vue';
import UploadDropzone from '~/vue_shared/components/upload_dropzone/upload_dropzone.vue';
import { uploadModel } from '~/ml/model_registry/services/upload_model';
import createModelVersionMutation from '~/ml/model_registry/graphql/mutations/create_model_version.mutation.graphql';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';

import MarkdownEditor from '~/vue_shared/components/markdown/markdown_editor.vue';
import { createModelVersionResponses } from '../graphql_mock_data';

Vue.use(VueApollo);

jest.mock('~/lib/utils/url_utility', () => ({
  ...jest.requireActual('~/lib/utils/url_utility'),
  visitUrl: jest.fn(),
  visitUrlWithAlerts: jest.fn(),
}));

jest.mock('~/ml/model_registry/services/upload_model', () => ({
  uploadModel: jest.fn(() => Promise.resolve()),
}));

describe('ModelVersionCreate', () => {
  let wrapper;
  let apolloProvider;

  const file = { name: 'file.txt', size: 1024 };
  const anotherFile = { name: 'another file.txt', size: 10 };
  const files = [file, anotherFile];

  beforeEach(() => {
    jest.spyOn(Sentry, 'captureException').mockImplementation();
  });

  afterEach(() => {
    apolloProvider = null;
  });

  const createWrapper = (
    createResolver = jest.fn().mockResolvedValue(createModelVersionResponses.success),
    provide = {},
  ) => {
    const requestHandlers = [[createModelVersionMutation, createResolver]];
    apolloProvider = createMockApollo(requestHandlers);

    wrapper = shallowMountExtended(ModelVersionCreate, {
      propsData: {
        modelPath: 'some/project/model/path',
        projectPath: 'some/project',
        markdownPreviewPath: '/markdown-preview',
      },
      provide: {
        maxAllowedFileSize: 99999,
        latestVersion: null,
        modelGid: 'gid://gitlab/Ml::Model/1',
        ...provide,
      },
      apolloProvider,
      stubs: {
        PageHeading,
        UploadDropzone,
      },
    });
  };

  const findDescription = () => wrapper.findByTestId('page-heading-description');
  const findPrimaryButton = () => wrapper.findByTestId('primary-button');
  const findSecondaryButton = () => wrapper.findByTestId('secondary-button');
  const findVersionInput = () => wrapper.findByTestId('versionId');
  const findDescriptionInput = () => wrapper.findByTestId('descriptionId');
  const findImportArtifactZone = () => wrapper.findComponent(ImportArtifactZone);
  const zone = () => wrapper.findComponent(UploadDropzone);
  const findGlAlert = () => wrapper.findComponent(GlAlert);
  const submitForm = async () => {
    findPrimaryButton().vm.$emit('click');
    await waitForPromises();
  };
  const artifactZoneLabel = () => wrapper.findByTestId('uploadArtifactsHeader');
  const findMarkdownEditor = () => wrapper.findComponent(MarkdownEditor);

  describe('Initial state', () => {
    beforeEach(() => {
      createWrapper();
    });

    describe('Form', () => {
      it('renders the title', () => {
        expect(wrapper.findByRole('heading').text()).toBe('New version');
      });

      it('renders the description', () => {
        expect(findDescription().text()).toBe(
          'Models have different versions. You can deploy and test versions. Complete the following fields to create a new version of the model.',
        );
      });

      it('renders the version input', () => {
        expect(findVersionInput().exists()).toBe(true);
      });

      it('renders the version input label for initial state', () => {
        expect(wrapper.findByTestId('versionDescriptionId').attributes().description).toBe(
          'Must be a semantic version.',
        );
        expect(wrapper.findByTestId('versionDescriptionId').attributes('invalid-feedback')).toBe(
          '',
        );
        expect(wrapper.findByTestId('versionDescriptionId').attributes('valid-feedback')).toBe('');
      });

      it('renders the description input', () => {
        expect(findDescriptionInput().exists()).toBe(true);
      });

      it('renders the import artifact zone input', () => {
        expect(findImportArtifactZone().props()).toEqual({
          path: null,
          submitOnSelect: false,
        });
      });

      it('renders the create button', () => {
        expect(findPrimaryButton().props()).toMatchObject({
          variant: 'confirm',
          disabled: true,
        });
      });

      it('renders the cancel button', () => {
        expect(findSecondaryButton().props()).toMatchObject({
          variant: 'default',
          disabled: false,
        });
      });

      it('disables the create button in the modal when semver is incorrect', () => {
        expect(findPrimaryButton().props()).toMatchObject({
          variant: 'confirm',
          disabled: true,
        });
      });

      it('does not render the alert by default', () => {
        expect(findGlAlert().exists()).toBe(false);
      });

      it('displays the title of the artifacts uploader', () => {
        expect(artifactZoneLabel().attributes('label')).toBe('Upload artifacts');
      });
    });
  });

  describe('Markdown editor', () => {
    it('should show markdown editor', () => {
      createWrapper();

      expect(findMarkdownEditor().exists()).toBe(true);

      expect(findMarkdownEditor().props()).toMatchObject({
        enableContentEditor: true,
        formFieldProps: {
          id: 'model-version-description',
          name: 'model-version-description',
          placeholder: 'Enter a model version description',
        },
        markdownDocsPath: '/help/user/markdown',
        renderMarkdownPath: '/markdown-preview',
        uploadsPath: '',
      });
    });
  });

  describe('It reacts to semantic version input', () => {
    beforeEach(() => {
      createWrapper();
    });
    it('renders the version input label for initial state', () => {
      expect(wrapper.findByTestId('versionDescriptionId').attributes('invalid-feedback')).toBe('');
      expect(findPrimaryButton().props()).toMatchObject({
        variant: 'confirm',
        disabled: true,
      });
    });
    it.each(['1.0', '1', 'abc', '1.abc', '1.0.0.0'])(
      'renders the version input label for invalid state',
      async (version) => {
        findVersionInput().vm.$emit('input', version);
        await nextTick();
        expect(wrapper.findByTestId('versionDescriptionId').attributes('invalid-feedback')).toBe(
          'Version is not a valid semantic version.',
        );
        expect(findPrimaryButton().props()).toMatchObject({
          variant: 'confirm',
          disabled: true,
        });
      },
    );
    it.each(['1.0.0', '0.0.0-b', '24.99.99-b99'])(
      'renders the version input label for valid state',
      async (version) => {
        findVersionInput().vm.$emit('input', version);
        await nextTick();
        expect(wrapper.findByTestId('versionDescriptionId').attributes('valid-feedback')).toBe(
          'Version is valid semantic version.',
        );
        expect(findPrimaryButton().props()).toMatchObject({
          variant: 'confirm',
          disabled: false,
        });
      },
    );
  });

  describe('Latest version available', () => {
    beforeEach(() => {
      createWrapper(undefined, { latestVersion: '1.2.3' });
    });

    it('renders the version input label', () => {
      expect(wrapper.findByTestId('versionDescriptionId').attributes().description).toBe(
        'Must be a semantic version. Latest version is 1.2.3',
      );
    });
  });

  describe('Successful flow', () => {
    beforeEach(async () => {
      createWrapper();
      findVersionInput().vm.$emit('input', '1.0.0');
      findDescriptionInput().vm.$emit('input', 'My model version description');
      zone().vm.$emit('change', files);
      jest.spyOn(apolloProvider.defaultClient, 'mutate');

      await submitForm();
    });

    it('Makes a create mutation upon confirm', () => {
      expect(apolloProvider.defaultClient.mutate).toHaveBeenCalledWith(
        expect.objectContaining({
          mutation: createModelVersionMutation,
          variables: {
            modelId: 'gid://gitlab/Ml::Model/1',
            projectPath: 'some/project',
            version: '1.0.0',
            description: 'My model version description',
          },
        }),
      );
    });

    it('Uploads a file mutation upon confirm', () => {
      expect(uploadModel).toHaveBeenCalledWith({
        file,
        importPath: '/api/v4/projects/1/packages/ml_models/1/files/',
        subfolder: '',
        maxAllowedFileSize: 99999,
        onUploadProgress: expect.any(Function),
        cancelToken: expect.any(Object),
      });
    });

    it('Visits the model versions page upon successful create mutation', async () => {
      createWrapper();

      await submitForm();

      expect(visitUrlWithAlerts).toHaveBeenCalledWith('/some/project/-/ml/models/1/versions/1', [
        {
          id: 'import-artifact-alert',
          message: 'Artifacts uploaded successfully.',
          variant: 'info',
        },
      ]);
    });

    it('clicking on secondary button clears the form', async () => {
      createWrapper();

      await findSecondaryButton().vm.$emit('click');

      expect(visitUrl).toHaveBeenCalledWith('some/project/model/path');
    });
  });

  describe('Failed flow', () => {
    it('Displays an alert upon failed create mutation', async () => {
      const failedCreateResolver = jest.fn().mockResolvedValue(createModelVersionResponses.failure);
      createWrapper(failedCreateResolver);

      findVersionInput().vm.$emit('input', '1.0.0');

      await submitForm();

      expect(findGlAlert().text()).toBe('Version is invalid');
    });

    describe('Failed flow with file upload retried', () => {
      beforeEach(async () => {
        createWrapper();
        findVersionInput().vm.$emit('input', '1.0.0');
        zone().vm.$emit('change', files);
        await nextTick();
        uploadModel.mockRejectedValueOnce('Artifact import error.');

        await submitForm();
      });

      it('Visits the model versions page upon successful create mutation', async () => {
        await submitForm();

        expect(visitUrlWithAlerts).toHaveBeenCalledWith('/some/project/-/ml/models/1/versions/1', [
          {
            id: 'import-artifact-alert',
            message: 'Artifact uploads completed with errors. file.txt: Artifact import error.',
            variant: 'danger',
          },
        ]);
      });

      it('Uploads the model upon retry', async () => {
        await submitForm();

        expect(uploadModel).toHaveBeenCalledWith({
          file,
          importPath: '/api/v4/projects/1/packages/ml_models/1/files/',
          subfolder: '',
          maxAllowedFileSize: 99999,
          onUploadProgress: expect.any(Function),
          cancelToken: expect.any(Object),
        });
      });
    });
  });
});

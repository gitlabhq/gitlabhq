import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { GlModal } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import { visitUrl } from '~/lib/utils/url_utility';
import ModelCreate from '~/ml/model_registry/components/model_create.vue';
import ImportArtifactZone from '~/ml/model_registry/components/import_artifact_zone.vue';
import UploadDropzone from '~/vue_shared/components/upload_dropzone/upload_dropzone.vue';
import { uploadModel } from '~/ml/model_registry/services/upload_model';
import createModelMutation from '~/ml/model_registry/graphql/mutations/create_model.mutation.graphql';
import createModelVersionMutation from '~/ml/model_registry/graphql/mutations/create_model_version.mutation.graphql';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';

import { createMockDirective, getBinding } from 'helpers/vue_mock_directive';
import { MODEL_CREATION_MODAL_ID } from '~/ml/model_registry/constants';
import MarkdownEditor from '~/vue_shared/components/markdown/markdown_editor.vue';
import { createModelResponses, createModelVersionResponses } from '../graphql_mock_data';

Vue.use(VueApollo);

jest.mock('~/lib/utils/url_utility', () => ({
  ...jest.requireActual('~/lib/utils/url_utility'),
  visitUrl: jest.fn(),
}));

jest.mock('~/ml/model_registry/services/upload_model', () => ({
  uploadModel: jest.fn(() => Promise.resolve()),
}));

describe('ModelCreate', () => {
  let wrapper;
  let apolloProvider;

  const file = { name: 'file.txt', size: 1024 };

  beforeEach(() => {
    jest.spyOn(Sentry, 'captureException').mockImplementation();
  });

  afterEach(() => {
    apolloProvider = null;
  });

  const createWrapper = (
    createModelResolver = jest.fn().mockResolvedValue(createModelResponses.success),
    createModelVersionResolver = jest.fn().mockResolvedValue(createModelVersionResponses.success),
    createModelVisible = false,
  ) => {
    const requestHandlers = [
      [createModelMutation, createModelResolver],
      [createModelVersionMutation, createModelVersionResolver],
    ];
    apolloProvider = createMockApollo(requestHandlers);

    wrapper = shallowMountExtended(ModelCreate, {
      propsData: {
        createModelVisible,
      },
      provide: {
        projectPath: 'some/project',
        maxAllowedFileSize: 99999,
        markdownPreviewPath: '/markdown-preview',
      },
      directives: {
        GlModal: createMockDirective('gl-modal'),
      },
      apolloProvider,
      stubs: {
        ImportArtifactZone,
      },
    });
  };

  const findModalButton = () => wrapper.findByText('Create model');
  const findNameInput = () => wrapper.findByTestId('nameId');
  const findVersionInput = () => wrapper.findByTestId('versionId');
  const findVersionGroup = () => wrapper.findByTestId('versionGroupId');
  const findVersionDescriptionGroup = () => wrapper.findByTestId('versionDescriptionGroupId');
  const findDescriptionGroup = () => wrapper.findByTestId('descriptionGroupId');
  const findDescriptionInput = () => wrapper.findByTestId('descriptionId');
  const findVersionDescriptionInput = () => wrapper.findByTestId('versionDescriptionId');
  const findImportArtifactZone = () => wrapper.findComponent(ImportArtifactZone);
  const zone = () => wrapper.findComponent(UploadDropzone);
  const findGlModal = () => wrapper.findComponent(GlModal);
  const findGlAlert = () => wrapper.findByTestId('modalCreateAlert');
  const submitForm = async () => {
    findGlModal().vm.$emit('primary', new Event('primary'));
    await waitForPromises();
  };
  const findArtifactZoneLabel = () => wrapper.findByTestId('importArtifactZoneLabel');
  const findMarkdownEditor = () => wrapper.findComponent(MarkdownEditor);
  const findModelNameGroup = () => wrapper.findByTestId('nameGroupId');

  describe('Initial state', () => {
    describe('Modal closed', () => {
      beforeEach(() => {
        createWrapper();
      });

      it('does not show modal', () => {
        expect(findGlModal().props('visible')).toBe(false);
      });

      it('renders the modal button', () => {
        expect(findModalButton().text()).toBe('Create model');
        expect(getBinding(findModalButton().element, 'gl-modal').value).toBe(
          MODEL_CREATION_MODAL_ID,
        );
      });
    });

    describe('Markdown editor', () => {
      it('should show markdown editor', () => {
        createWrapper();

        expect(findMarkdownEditor().props()).toMatchObject({
          enableContentEditor: true,
          formFieldProps: {
            id: 'model-description',
            name: 'model-description',
            placeholder: 'Enter a model description',
          },
          markdownDocsPath: '/help/user/markdown',
          renderMarkdownPath: '/markdown-preview',
          uploadsPath: '',
          restrictedToolBarItems: ['full-screen'],
        });
      });
    });

    describe('Modal open', () => {
      beforeEach(() => {
        createWrapper(
          jest.fn().mockResolvedValue(createModelResponses.success),
          jest.fn().mockResolvedValue(createModelVersionResponses.success),
          true,
        );
      });

      it('renders the name input', () => {
        expect(findNameInput().exists()).toBe(true);
      });

      it('renders the model name group description', () => {
        expect(findModelNameGroup().attributes('description')).toBe(
          ModelCreate.modal.nameDescription,
        );
      });

      it('renders the name label', () => {
        expect(findModelNameGroup().attributes('label')).toBe(ModelCreate.modal.modelName);
      });

      it('renders the version input', () => {
        expect(findVersionInput().exists()).toBe(true);
      });

      it('renders the version label', () => {
        expect(findVersionGroup().attributes('label')).toBe('Version');
      });

      it('renders the version placeholder', () => {
        expect(findVersionInput().attributes('placeholder')).toBe(
          ModelCreate.modal.versionPlaceholder,
        );
      });

      it('renders the version group', () => {
        expect(findVersionGroup().attributes()).toMatchObject({
          description: 'Example: 1.0.0',
          optional: 'true',
          optionaltext: '(Optional)',
          label: 'Version',
        });
      });

      it('renders the version description group', () => {
        expect(findVersionDescriptionGroup().attributes()).toMatchObject({
          optional: 'true',
          optionaltext: '(Optional)',
          label: 'Version description',
        });
      });

      it('renders the description group', () => {
        expect(findDescriptionGroup().attributes()).toMatchObject({
          optionaltext: '(Optional)',
          optional: 'true',
          label: 'Model description',
        });
      });

      it('renders the description input', () => {
        expect(findDescriptionInput().exists()).toBe(true);
      });

      it('renders the description input text', () => {
        expect(findVersionGroup().attributes('valid-feedback')).toBe(
          ModelCreate.modal.validVersion,
        );
      });

      it('renders the version description input', () => {
        expect(findVersionDescriptionInput().exists()).toBe(true);
      });

      it('renders the import artifact zone input', () => {
        expect(findImportArtifactZone().exists()).toBe(false);
      });

      it('does not displays the title of the artifacts uploader', () => {
        expect(findArtifactZoneLabel().exists()).toBe(false);
      });

      it('displays the title of the artifacts uploader when a version is entered', async () => {
        findNameInput().vm.$emit('input', 'gpt-alice-1');
        findVersionInput().vm.$emit('input', '1.0.0');
        findVersionDescriptionInput().vm.$emit('input', 'My version description');
        await Vue.nextTick();
        expect(findArtifactZoneLabel().attributes('label')).toBe('Upload artifacts');
      });

      it('renders the import artifact zone input with version entered', async () => {
        findNameInput().vm.$emit('input', 'gpt-alice-1');
        findVersionInput().vm.$emit('input', '1.0.0');
        await waitForPromises();
        expect(findImportArtifactZone().props()).toEqual({
          path: null,
          submitOnSelect: false,
        });
      });

      it('renders the import modal', () => {
        expect(findGlModal().props()).toMatchObject({
          modalId: 'create-model-modal',
          title: 'Create model, version & import artifacts',
          size: 'lg',
        });
      });

      it('renders the create button in the modal', () => {
        expect(findGlModal().props('actionPrimary')).toEqual({
          attributes: { variant: 'confirm', disabled: true },
          text: 'Create',
        });
      });

      it('renders the cancel button in the modal', () => {
        expect(findGlModal().props('actionSecondary')).toEqual({
          text: 'Cancel',
          attributes: { variant: 'default' },
        });
      });

      it('does not render the alert by default', () => {
        expect(findGlAlert().exists()).toBe(false);
      });
    });

    describe('It reacts to semantic version input', () => {
      beforeEach(() => {
        createWrapper();
      });
      it('renders the version input label for initial state', () => {
        expect(findVersionGroup().attributes('state')).toBe('true');
        expect(findGlModal().props('actionPrimary')).toEqual({
          attributes: { variant: 'confirm', disabled: true },
          text: 'Create',
        });
      });
      it.each(['1.0', '1', 'abc', '1.abc', '1.0.0.0'])(
        'renders the version input label for invalid state',
        async (version) => {
          findVersionInput().vm.$emit('input', version);
          await nextTick();
          expect(findVersionGroup().attributes()).not.toContain('state');
          expect(findVersionGroup().attributes('invalid-feedback')).toBe(
            ModelCreate.modal.versionInvalid,
          );
          expect(findVersionGroup().attributes('description')).toBe('');
          expect(findGlModal().props('actionPrimary')).toEqual({
            attributes: { variant: 'confirm', disabled: true },
            text: 'Create',
          });
        },
      );
      it.each(['1.0.0', '0.0.0-b', '24.99.99-b99'])(
        'renders the version input label for valid state',
        async (version) => {
          findVersionInput().vm.$emit('input', version);
          await nextTick();
          expect(findVersionGroup().attributes('state')).toBe('true');
          expect(findVersionGroup().attributes('valid-feedback')).toBe(
            ModelCreate.modal.versionValid,
          );
          expect(findVersionGroup().attributes('description')).toBe('');
          expect(findGlModal().props('actionPrimary')).toEqual({
            attributes: { variant: 'confirm', disabled: true },
            text: 'Create',
          });
        },
      );
      it.each(['1.0.0', '0.0.0-b', '24.99.99-b99'])(
        'renders the version input label for valid state',
        async (version) => {
          findNameInput().vm.$emit('input', 'gpt-alice-1');
          findVersionInput().vm.$emit('input', version);
          await nextTick();
          expect(findVersionGroup().attributes('state')).toBe('true');
          expect(findGlModal().props('actionPrimary')).toEqual({
            attributes: { variant: 'confirm', disabled: false },
            text: 'Create',
          });
        },
      );

      it.each(['model name', ' modelname', 'modelname ', ' ', ''])(
        'renders the modelnames as invalid',
        async (name) => {
          findNameInput().vm.$emit('input', name);
          await nextTick();
          expect(findModelNameGroup().attributes()).not.toContain('state');
        },
      );
      it.each(['modelname', 'model-name', 'MODELname', 'model_name'])(
        'renders the modelnames as invalid',
        async (name) => {
          findNameInput().vm.$emit('input', name);
          await nextTick();
          expect(findModelNameGroup().attributes('state')).toBe('true');
        },
      );
    });

    it('clicking on secondary button clears the form', async () => {
      createWrapper();

      await findNameInput().vm.$emit('input', 'my_model');

      await findGlModal().vm.$emit('secondary');

      expect(findVersionInput().attributes('value')).toBe(undefined);
    });
  });

  describe('Successful flow with version', () => {
    beforeEach(async () => {
      createWrapper();
      findNameInput().vm.$emit('input', 'gpt-alice-1');
      findMarkdownEditor().vm.$emit('input', 'My model description');
      findVersionInput().vm.$emit('input', '1.0.0');
      findVersionDescriptionInput().vm.$emit('input', 'My version description');
      await Vue.nextTick();
      zone().vm.$emit('change', file);
      jest.spyOn(apolloProvider.defaultClient, 'mutate');

      await submitForm();
    });

    it('Makes a create model mutation upon confirm', () => {
      expect(apolloProvider.defaultClient.mutate).toHaveBeenCalledWith(
        expect.objectContaining({
          mutation: createModelMutation,
          variables: {
            projectPath: 'some/project',
            name: 'gpt-alice-1',
            description: 'My model description',
          },
        }),
      );
    });

    it('Makes a create model version mutation upon confirm', () => {
      expect(apolloProvider.defaultClient.mutate).toHaveBeenCalledWith(
        expect.objectContaining({
          mutation: createModelVersionMutation,
          variables: {
            modelId: 'gid://gitlab/Ml::Model/1',
            projectPath: 'some/project',
            version: '1.0.0',
            description: 'My version description',
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

    it('Visits the model versions page upon successful create mutation', () => {
      expect(visitUrl).toHaveBeenCalledWith('/some/project/-/ml/models/1/versions/1');
    });
  });

  describe('Successful flow without version', () => {
    beforeEach(async () => {
      createWrapper();
      findNameInput().vm.$emit('input', 'gpt-alice-1');
      findDescriptionInput().vm.$emit('input', 'My model description');
      jest.spyOn(apolloProvider.defaultClient, 'mutate');

      await submitForm();
    });

    it('Visits the model page upon successful create mutation without a version', () => {
      expect(visitUrl).toHaveBeenCalledWith('/some/project/-/ml/models/1');
    });
  });

  describe('Failed flow with version', () => {
    beforeEach(async () => {
      const failedCreateModelVersionResolver = jest
        .fn()
        .mockResolvedValue(createModelVersionResponses.failure);
      createWrapper(undefined, failedCreateModelVersionResolver);
      jest.spyOn(apolloProvider.defaultClient, 'mutate');

      findNameInput().vm.$emit('input', 'gpt-alice-1');
      findVersionInput().vm.$emit('input', '1.0.0');
      findVersionDescriptionInput().vm.$emit('input', 'My version description');
      await Vue.nextTick();
      zone().vm.$emit('change', file);
      await submitForm();
    });

    it('Displays an alert upon failed model  create mutation', () => {
      expect(findGlAlert().text()).toBe('Version is invalid');
    });
  });

  describe('Failed flow with version retried', () => {
    beforeEach(async () => {
      const failedCreateModelVersionResolver = jest
        .fn()
        .mockResolvedValueOnce(createModelVersionResponses.failure);
      createWrapper(undefined, failedCreateModelVersionResolver);
      jest.spyOn(apolloProvider.defaultClient, 'mutate');

      findNameInput().vm.$emit('input', 'gpt-alice-1');
      findVersionInput().vm.$emit('input', '1.0.0');
      findVersionDescriptionInput().vm.$emit('input', 'My retried version description');
      await submitForm();
    });

    it('Displays an alert upon failed model create mutation', async () => {
      expect(findGlAlert().text()).toBe('Version is invalid');

      await submitForm();

      expect(apolloProvider.defaultClient.mutate).toHaveBeenCalledWith(
        expect.objectContaining({
          mutation: createModelVersionMutation,
          variables: {
            modelId: 'gid://gitlab/Ml::Model/1',
            projectPath: 'some/project',
            version: '1.0.0',
            description: 'My retried version description',
          },
        }),
      );
    });
  });

  describe('Failed flow with file upload retried', () => {
    beforeEach(async () => {
      createWrapper();
      findNameInput().vm.$emit('input', 'gpt-alice-1');
      findVersionInput().vm.$emit('input', '1.0.0');
      findDescriptionInput().vm.$emit('input', 'My model description');
      findVersionDescriptionInput().vm.$emit('input', 'My version description');
      await Vue.nextTick();
      zone().vm.$emit('change', file);
      uploadModel.mockRejectedValueOnce('Artifact import error.');
      await submitForm();
    });

    it('Visits the model versions page upon successful create mutation', async () => {
      await submitForm(); // retry submit
      expect(visitUrl).toHaveBeenCalledWith('/some/project/-/ml/models/1/versions/1');
    });

    it('Uploads a file mutation upon confirm', async () => {
      await submitForm(); // retry submit
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

  describe('Failed flow without version', () => {
    describe('Mutation errors', () => {
      beforeEach(async () => {
        const failedCreateModelResolver = jest
          .fn()
          .mockResolvedValue(createModelResponses.validationFailure);
        createWrapper(failedCreateModelResolver);
        jest.spyOn(apolloProvider.defaultClient, 'mutate');

        findNameInput().vm.$emit('input', 'gpt-alice-1');
        await submitForm();
      });

      it('Displays an alert upon failed model  create mutation', () => {
        expect(findGlAlert().text()).toBe("Name is invalid, Name can't be blank");
      });

      it('Displays an alert upon an exception', () => {
        expect(findGlAlert().text()).toBe("Name is invalid, Name can't be blank");
      });
    });

    it('Logs to sentry upon an exception', async () => {
      const error = new Error('Runtime error');
      createWrapper();
      jest.spyOn(apolloProvider.defaultClient, 'mutate').mockImplementation(() => {
        throw error;
      });

      findNameInput().vm.$emit('input', 'gpt-alice-1');
      await submitForm();

      expect(Sentry.captureException).toHaveBeenCalledWith(error);
    });
  });
});

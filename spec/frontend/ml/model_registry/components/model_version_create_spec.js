import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { GlAlert, GlModal } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import { visitUrl } from '~/lib/utils/url_utility';
import ModelVersionCreate from '~/ml/model_registry/components/model_version_create.vue';
import ImportArtifactZone from '~/ml/model_registry/components/import_artifact_zone.vue';
import { uploadModel } from '~/ml/model_registry/services/upload_model';
import createModelVersionMutation from '~/ml/model_registry/graphql/mutations/create_model_version.mutation.graphql';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';

import { createModelVersionResponses } from '../graphql_mock_data';

Vue.use(VueApollo);

jest.mock('~/lib/utils/url_utility', () => ({
  ...jest.requireActual('~/lib/utils/url_utility'),
  visitUrl: jest.fn(),
}));

jest.mock('~/ml/model_registry/services/upload_model', () => ({
  uploadModel: jest.fn(),
}));

describe('ModelVersionCreate', () => {
  let wrapper;
  let apolloProvider;

  beforeEach(() => {
    jest.spyOn(Sentry, 'captureException').mockImplementation();
  });

  afterEach(() => {
    apolloProvider = null;
  });

  const createWrapper = (
    createResolver = jest.fn().mockResolvedValue(createModelVersionResponses.success),
  ) => {
    const requestHandlers = [[createModelVersionMutation, createResolver]];
    apolloProvider = createMockApollo(requestHandlers);

    wrapper = shallowMountExtended(ModelVersionCreate, {
      provide: {
        projectPath: 'some/project',
      },
      propsData: {
        modelGid: 'gid://gitlab/Ml::Model/1',
      },
      apolloProvider,
    });
  };

  const findModalButton = () => wrapper.findByText('Create model version');
  const findVersionInput = () => wrapper.findByTestId('versionId');
  const findDescriptionInput = () => wrapper.findByTestId('descriptionId');
  const findImportArtifactZone = () => wrapper.findComponent(ImportArtifactZone);
  const findGlModal = () => wrapper.findComponent(GlModal);
  const findGlAlert = () => wrapper.findComponent(GlAlert);
  const submitForm = async () => {
    findGlModal().vm.$emit('primary', new Event('primary'));
    await waitForPromises();
  };

  describe('Initial state', () => {
    beforeEach(() => {
      createWrapper();
    });

    it('renders the modal button', () => {
      expect(findModalButton().text()).toBe('Create model version');
    });

    describe('Modal open', () => {
      beforeEach(() => {
        findModalButton().trigger('click');
      });

      it('renders the version input', () => {
        expect(findVersionInput().exists()).toBe(true);
      });

      it('renders the version input label', () => {
        expect(wrapper.find('[description="Enter a semver version."]').exists()).toBe(true);
      });

      it('renders the description input', () => {
        expect(findDescriptionInput().exists()).toBe(true);
      });

      it('renders the import artifact zone input', () => {
        expect(findImportArtifactZone().props()).toEqual({
          path: null,
          submitOnSelect: false,
          value: { file: null, subfolder: '' },
        });
      });

      it('renders the import modal', () => {
        expect(findGlModal().props()).toMatchObject({
          modalId: 'create-model-version-modal',
          title: 'Create model version & import artifacts',
          size: 'sm',
        });
      });

      it('renders the cancel button in the modal', () => {
        expect(findGlModal().props('actionCancel')).toEqual({ text: 'Cancel' });
      });

      it('renders the create button in the modal', () => {
        expect(findGlModal().props('actionPrimary')).toEqual({
          attributes: { variant: 'confirm' },
          text: 'Create & import',
        });
      });

      it('does not render the alert by default', () => {
        expect(findGlAlert().exists()).toBe(false);
      });
    });
  });

  describe('Successful flow', () => {
    beforeEach(async () => {
      createWrapper();
      findVersionInput().vm.$emit('input', '1.0.0');
      findDescriptionInput().vm.$emit('input', 'My model version description');
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
        file: null,
        importPath: '/api/v4/projects/1/packages/ml_models/1/files/',
        subfolder: '',
      });
    });
    it('Visits the model versions page upon successful create mutation', async () => {
      createWrapper();

      await submitForm();

      expect(visitUrl).toHaveBeenCalledWith('/some/project/-/ml/models/1/versions/1');
    });
  });

  describe('Failed flow', () => {
    it('Displays an alert upon failed create mutation', async () => {
      const failedCreateResolver = jest.fn().mockResolvedValue(createModelVersionResponses.failure);
      createWrapper(failedCreateResolver);

      await submitForm();

      expect(findGlAlert().text()).toBe('Version is invalid');
    });

    it('Displays an alert upon an exception', async () => {
      createWrapper();
      uploadModel.mockRejectedValueOnce('Runtime error');

      await submitForm();

      expect(findGlAlert().text()).toBe('Runtime error');
    });

    it('Logs to sentry upon an exception', async () => {
      createWrapper();
      uploadModel.mockRejectedValueOnce('Runtime error');

      await submitForm();

      expect(Sentry.captureException).toHaveBeenCalledWith('Runtime error');
    });

    describe('Failed flow with file upload retried', () => {
      beforeEach(async () => {
        createWrapper();
        uploadModel.mockRejectedValueOnce('Artifact import error.');

        await submitForm();
      });

      it('Visits the model versions page upon successful create mutation', async () => {
        expect(findGlAlert().text()).toBe('Artifact import error.');

        await submitForm();

        expect(visitUrl).toHaveBeenCalledWith('/some/project/-/ml/models/1/versions/1');
      });
    });
  });
});

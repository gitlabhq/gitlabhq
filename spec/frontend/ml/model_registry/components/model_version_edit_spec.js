import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { GlModal } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import { visitUrl } from '~/lib/utils/url_utility';
import ModelVersionEdit from '~/ml/model_registry/components/model_version_edit.vue';

import editModelVersionMutation from '~/ml/model_registry/graphql/mutations/edit_model_version.mutation.graphql';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';

import { createMockDirective } from 'helpers/vue_mock_directive';
import MarkdownEditor from '~/vue_shared/components/markdown/markdown_editor.vue';
import { editModelVersionResponses, modelWithVersion } from '../graphql_mock_data';

Vue.use(VueApollo);

jest.mock('~/lib/utils/url_utility', () => ({
  ...jest.requireActual('~/lib/utils/url_utility'),
  visitUrl: jest.fn(),
}));

describe('ModelVersionEdit', () => {
  let wrapper;
  let apolloProvider;

  beforeEach(() => {
    jest.spyOn(Sentry, 'captureException').mockImplementation();
  });

  afterEach(() => {
    apolloProvider = null;
  });

  const createWrapper = (
    modelVersionProp = modelWithVersion,
    editModelVersionResolver = jest.fn().mockResolvedValue(editModelVersionResponses.success),
  ) => {
    const requestHandlers = [[editModelVersionMutation, editModelVersionResolver]];
    apolloProvider = createMockApollo(requestHandlers);

    wrapper = shallowMountExtended(ModelVersionEdit, {
      propsData: { modelWithVersion: modelVersionProp, disableAttachments: true },
      provide: {
        projectPath: 'some/project',
        maxAllowedFileSize: 99999,
        markdownPreviewPath: '/markdown-preview',
        modelId: 'gid://gitlab/Ml::Model/1',
      },
      directives: {
        GlModal: createMockDirective('gl-modal'),
      },
      apolloProvider,
    });
  };

  const findEditModal = () => wrapper.findComponent(ModelVersionEdit);
  const findModelDescription = () => wrapper.findByTestId('description-id');
  const findMarkdownEditor = () => wrapper.findComponent(MarkdownEditor);
  const findGlModal = () => wrapper.findComponent(GlModal);
  const findGlAlert = () => wrapper.findByTestId('modal-edit-alert');
  const submitForm = async () => {
    findGlModal().vm.$emit('primary', new Event('primary'));
    await waitForPromises();
  };
  const findDescriptionGroup = () => wrapper.findByTestId('description-group-id');

  describe('Initial state', () => {
    beforeEach(() => {
      createWrapper();
    });

    it('renders the component', () => {
      expect(findEditModal().exists()).toBe(true);
    });

    it('pre-populates the model description input', () => {
      expect(findModelDescription().attributes('value')).toBe(modelWithVersion.version.description);
    });

    it('renders the edit button in the modal', () => {
      expect(findGlModal().props('actionPrimary')).toEqual({
        attributes: { variant: 'confirm' },
        text: 'Save changes',
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

    it('should show optional description text', () => {
      expect(findDescriptionGroup().attributes('optionaltext')).toBe('(Optional)');
      expect(findDescriptionGroup().attributes('optional')).toBe('true');
    });

    it('shows the description label', () => {
      expect(findDescriptionGroup().attributes('label')).toBe('Description');
    });

    describe('Markdown editor', () => {
      it('should show markdown editor', () => {
        createWrapper();
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
          restrictedToolBarItems: ['full-screen'],
        });
      });
    });
  });

  describe('Successful flow with version', () => {
    beforeEach(async () => {
      createWrapper();
      findMarkdownEditor().vm.$emit('input', 'A model version description');
      await Vue.nextTick();
      jest.spyOn(apolloProvider.defaultClient, 'mutate');

      await submitForm();
    });

    it('makes an edit model mutation upon confirm', () => {
      expect(apolloProvider.defaultClient.mutate).toHaveBeenCalledWith(
        expect.objectContaining({
          mutation: editModelVersionMutation,
          variables: {
            modelId: 'gid://gitlab/Ml::Model/1',
            description: 'A model version description',
            projectPath: 'some/project',
            version: '1.0.4999',
          },
        }),
      );
      expect(apolloProvider.defaultClient.mutate).toHaveBeenCalledTimes(1);
      expect(findGlAlert().exists()).toBe(false);
      const mockedShowPath =
        editModelVersionResponses.success.data.mlModelVersionEdit.modelVersion._links.showPath;
      expect(visitUrl).toHaveBeenCalledWith(mockedShowPath);
    });
  });

  describe('Failed flow', () => {
    describe('if backend returns error', () => {
      beforeEach(async () => {
        createWrapper(
          modelWithVersion,
          jest.fn().mockResolvedValue(editModelVersionResponses.validationFailure),
        );
        findMarkdownEditor().vm.$emit('input', 'My model version description');
        await Vue.nextTick();
        jest.spyOn(apolloProvider.defaultClient, 'mutate');

        await submitForm();
      });

      it('shows an alert when the mutation fails', () => {
        expect(findGlAlert().exists()).toBe(true);
        expect(findGlAlert().text()).toBe('Unable to update model version');
      });

      it('does not navigate away when the mutation fails', () => {
        expect(visitUrl).not.toHaveBeenCalled();
      });
    });
    describe('when the network fails', () => {
      const MOCKED_ERROR_MESSAGE = 'Something went wrong';

      beforeEach(async () => {
        createWrapper(
          modelWithVersion,
          jest.fn().mockRejectedValue(new Error(MOCKED_ERROR_MESSAGE)),
        );
        findMarkdownEditor().vm.$emit('input', 'My model version description');
        await Vue.nextTick();
        jest.spyOn(apolloProvider.defaultClient, 'mutate');

        await submitForm();
      });

      it('shows an alert when the mutation fails', () => {
        expect(findGlAlert().exists()).toBe(true);
        expect(findGlAlert().text()).toContain(MOCKED_ERROR_MESSAGE);
        expect(Sentry.captureException).toHaveBeenCalled();
      });
    });
  });
});

import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import { visitUrl } from '~/lib/utils/url_utility';
import ModelEdit from '~/ml/model_registry/components/model_edit.vue';
import editModelMutation from '~/ml/model_registry/graphql/mutations/edit_model.mutation.graphql';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';

import MarkdownEditor from '~/vue_shared/components/markdown/markdown_editor.vue';
import { editModelResponses, model } from '../graphql_mock_data';

Vue.use(VueApollo);

jest.mock('~/lib/utils/url_utility', () => ({
  ...jest.requireActual('~/lib/utils/url_utility'),
  visitUrl: jest.fn(),
}));

describe('ModelEdit', () => {
  let wrapper;
  let apolloProvider;

  beforeEach(() => {
    jest.spyOn(Sentry, 'captureException').mockImplementation();
  });

  afterEach(() => {
    apolloProvider = null;
  });

  const createWrapper = (
    modelProp = model,
    editModelResolver = jest.fn().mockResolvedValue(editModelResponses.success),
  ) => {
    const requestHandlers = [[editModelMutation, editModelResolver]];
    apolloProvider = createMockApollo(requestHandlers);

    wrapper = shallowMountExtended(ModelEdit, {
      propsData: {
        model: modelProp,
        disableAttachments: true,
        projectPath: 'some/project',
        markdownPreviewPath: '/markdown-preview',
        modelPath: 'model/path',
      },
      apolloProvider,
    });
  };

  const findPrimaryButton = () => wrapper.findByTestId('primary-button');
  const findSecondaryButton = () => wrapper.findByTestId('secondary-button');
  const findModelName = () => wrapper.findByTestId('nameId');
  const findModelDescription = () => wrapper.findByTestId('descriptionId');
  const findMarkdownEditor = () => wrapper.findComponent(MarkdownEditor);
  const findGlAlert = () => wrapper.findByTestId('edit-alert');
  const submitForm = async () => {
    findPrimaryButton().vm.$emit('click');
    await waitForPromises();
  };

  describe('Initial state', () => {
    beforeEach(() => {
      createWrapper();
    });

    it('shows disabled model name input', () => {
      expect(findModelName().attributes('disabled')).toBe('true');
    });

    it('pre-populates the model name input', () => {
      expect(findModelName().attributes('value')).toBe(model.name);
    });

    it('pre-populates the model description input', () => {
      expect(findModelDescription().attributes('value')).toBe(model.description);
    });

    it('renders the edit button', () => {
      expect(findPrimaryButton().props()).toMatchObject({
        variant: 'confirm',
        disabled: false,
      });
    });

    it('renders the cancel button', () => {
      expect(findSecondaryButton().props()).toMatchObject({
        variant: 'default',
      });
    });

    it('does not render the alert by default', () => {
      expect(findGlAlert().exists()).toBe(false);
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
  });

  describe('Successful flow with version', () => {
    beforeEach(async () => {
      createWrapper();
      findMarkdownEditor().vm.$emit('input', 'My model description');
      await Vue.nextTick();
      jest.spyOn(apolloProvider.defaultClient, 'mutate');

      await submitForm();
    });

    it('makes a create model mutation upon confirm', () => {
      expect(apolloProvider.defaultClient.mutate).toHaveBeenCalledWith(
        expect.objectContaining({
          mutation: editModelMutation,
          variables: {
            description: 'My model description',
            modelId: 1,
            name: model.name,
            projectPath: 'some/project',
          },
        }),
      );
    });
  });

  describe('Failed flow', () => {
    beforeEach(async () => {
      createWrapper(model, jest.fn().mockResolvedValue(editModelResponses.validationFailure));
      findMarkdownEditor().vm.$emit('input', 'My model description');
      await Vue.nextTick();
      jest.spyOn(apolloProvider.defaultClient, 'mutate');

      await submitForm();
    });

    it('shows an alert when the mutation fails', () => {
      expect(findGlAlert().text()).toBe('Unable to update model');
      expect(findGlAlert().exists()).toBe(true);
    });

    it('does not navigate away when the mutation fails', () => {
      expect(visitUrl).not.toHaveBeenCalled();
    });
  });
});

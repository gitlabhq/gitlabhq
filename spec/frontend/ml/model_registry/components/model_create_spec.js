import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import { visitUrl } from '~/lib/utils/url_utility';
import ModelCreate from '~/ml/model_registry/components/model_create.vue';
import createModelMutation from '~/ml/model_registry/graphql/mutations/create_model.mutation.graphql';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';

import MarkdownEditor from '~/vue_shared/components/markdown/markdown_editor.vue';
import { createModelResponses } from '../graphql_mock_data';

Vue.use(VueApollo);

jest.mock('~/lib/utils/url_utility', () => ({
  ...jest.requireActual('~/lib/utils/url_utility'),
  visitUrl: jest.fn(),
}));

describe('ModelCreate', () => {
  let wrapper;
  let apolloProvider;

  beforeEach(() => {
    jest.spyOn(Sentry, 'captureException').mockImplementation();
  });

  afterEach(() => {
    apolloProvider = null;
  });

  const createWrapper = (
    createModelResolver = jest.fn().mockResolvedValue(createModelResponses.success),
    createModelVisible = false,
  ) => {
    const requestHandlers = [[createModelMutation, createModelResolver]];
    apolloProvider = createMockApollo(requestHandlers);

    wrapper = shallowMountExtended(ModelCreate, {
      propsData: {
        createModelVisible,
        indexModelsPath: 'some/project/models',
        projectPath: 'some/project',
        markdownPreviewPath: '/markdown-preview',
      },
      provide: {
        maxAllowedFileSize: 99999,
      },
      apolloProvider,
    });
  };

  const findPrimaryButton = () => wrapper.findByTestId('primary-button');
  const findSecondaryButton = () => wrapper.findByTestId('secondary-button');
  const findNameInput = () => wrapper.findByTestId('nameId');
  const findDescriptionGroup = () => wrapper.findByTestId('descriptionGroupId');
  const findDescriptionInput = () => wrapper.findByTestId('descriptionId');
  const findGlAlert = () => wrapper.findByTestId('create-alert');
  const submitForm = async () => {
    findPrimaryButton().vm.$emit('click');
    await waitForPromises();
  };
  const findMarkdownEditor = () => wrapper.findComponent(MarkdownEditor);
  const findModelNameGroup = () => wrapper.findByTestId('nameGroupId');

  describe('Initial state', () => {
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

    describe('Form', () => {
      beforeEach(() => {
        createWrapper(jest.fn().mockResolvedValue(createModelResponses.success), true);
      });

      it('renders the name input', () => {
        expect(findNameInput().exists()).toBe(true);
      });

      it('renders the model name group description', () => {
        expect(findModelNameGroup().attributes('description')).toBe(
          ModelCreate.i18n.nameDescription,
        );
      });

      it('renders the name label', () => {
        expect(findModelNameGroup().attributes('label')).toBe(ModelCreate.i18n.modelName);
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

      it('does not render the alert by default', () => {
        expect(findGlAlert().exists()).toBe(false);
      });
    });

    describe('It reacts to semantic version input', () => {
      beforeEach(() => {
        createWrapper();
      });

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

    it('clicking on secondary button goes to model index page', async () => {
      createWrapper();

      await findNameInput().vm.$emit('input', 'my_model');

      await findSecondaryButton().vm.$emit('click');

      expect(visitUrl).toHaveBeenCalledWith('some/project/models');
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

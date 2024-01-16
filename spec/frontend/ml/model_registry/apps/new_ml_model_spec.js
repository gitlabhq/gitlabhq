import {
  GlAlert,
  GlButton,
  GlFormInput,
  GlFormTextarea,
  GlForm,
  GlSprintf,
  GlLink,
} from '@gitlab/ui';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import NewMlModel from '~/ml/model_registry/apps/new_ml_model.vue';
import createModelMutation from '~/ml/model_registry/graphql/mutations/create_model.mutation.graphql';
import createMockApollo from 'helpers/mock_apollo_helper';
import { visitUrl } from '~/lib/utils/url_utility';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import waitForPromises from 'helpers/wait_for_promises';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { createModelResponses } from '../graphql_mock_data';

jest.mock('~/lib/utils/url_utility', () => ({
  ...jest.requireActual('~/lib/utils/url_utility'),
  visitUrl: jest.fn(),
}));

describe('ml/model_registry/apps/new_ml_model.vue', () => {
  let wrapper;
  let apolloProvider;

  Vue.use(VueApollo);

  beforeEach(() => {
    jest.spyOn(Sentry, 'captureException').mockImplementation();
  });

  const mountComponent = (resolver = jest.fn().mockResolvedValue(createModelResponses.success)) => {
    const requestHandlers = [[createModelMutation, resolver]];
    apolloProvider = createMockApollo(requestHandlers);

    wrapper = shallowMountExtended(NewMlModel, {
      apolloProvider,
      propsData: { projectPath: 'project/path' },
      stubs: { GlSprintf },
    });
  };

  const findButton = () => wrapper.findComponent(GlButton);
  const findInput = () => wrapper.findComponent(GlFormInput);
  const findTextarea = () => wrapper.findComponent(GlFormTextarea);
  const findForm = () => wrapper.findComponent(GlForm);
  const findDocAlert = () => wrapper.findComponent(GlAlert);
  const findDocLink = () => findDocAlert().findComponent(GlLink);
  const findErrorAlert = () => wrapper.findByTestId('new-model-errors');

  const submitForm = async () => {
    findForm().vm.$emit('submit', { preventDefault: () => {} });
    await waitForPromises();
  };

  it('renders the button', () => {
    mountComponent();

    expect(findButton().text()).toBe('Create model');
  });

  it('shows link to docs', () => {
    mountComponent();

    expect(findDocAlert().text()).toBe(
      'Creating models is also possible through the MLflow client. Follow the documentation to learn more.',
    );
    expect(findDocLink().attributes().href).toBe('/help/user/project/ml/model_registry/index.md');
  });

  it('submits the query with correct parameters', async () => {
    const resolver = jest.fn().mockResolvedValue(createModelResponses.success);
    mountComponent(resolver);

    findInput().vm.$emit('input', 'model_name');
    findTextarea().vm.$emit('input', 'A description');

    await submitForm();

    expect(resolver).toHaveBeenLastCalledWith(
      expect.objectContaining({
        projectPath: 'project/path',
        name: 'model_name',
        description: 'A description',
      }),
    );
  });

  it('navigates to the new page when result is successful', async () => {
    mountComponent();

    await submitForm();

    expect(visitUrl).toHaveBeenCalledWith('/some/project/-/ml/models/1');
  });

  it('shows errors when result is a top level error', async () => {
    const error = new Error('Failure!');
    mountComponent(jest.fn().mockRejectedValue({ error }));

    await submitForm();

    expect(findErrorAlert().text()).toBe('An error has occurred when saving the model.');
    expect(visitUrl).not.toHaveBeenCalled();
  });

  it('shows errors when result is a validation error', async () => {
    mountComponent(jest.fn().mockResolvedValue(createModelResponses.validationFailure));

    await submitForm();

    expect(findErrorAlert().text()).toBe("Name is invalid, Name can't be blank");
    expect(visitUrl).not.toHaveBeenCalled();
  });
});

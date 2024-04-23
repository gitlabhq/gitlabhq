import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { ShowMlModelVersion } from '~/ml/model_registry/apps';
import ModelVersionDetail from '~/ml/model_registry/components/model_version_detail.vue';
import TitleArea from '~/vue_shared/components/registry/title_area.vue';
import LoadOrErrorOrShow from '~/ml/model_registry/components/load_or_error_or_show.vue';
import createMockApollo from 'helpers/mock_apollo_helper';
import getModelVersionQuery from '~/ml/model_registry/graphql/queries/get_model_version.query.graphql';
import waitForPromises from 'helpers/wait_for_promises';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import { modelVersionQuery, modelVersionWithCandidate } from '../graphql_mock_data';

Vue.use(VueApollo);

describe('ml/model_registry/apps/show_model_version.vue', () => {
  let wrapper;
  let apolloProvider;

  beforeEach(() => {
    jest.spyOn(Sentry, 'captureException').mockImplementation();
  });

  const createWrapper = (resolver = jest.fn().mockResolvedValue(modelVersionQuery)) => {
    const requestHandlers = [[getModelVersionQuery, resolver]];
    apolloProvider = createMockApollo(requestHandlers);

    wrapper = shallowMount(ShowMlModelVersion, {
      propsData: {
        modelName: 'blah',
        versionName: '1.2.3',
        modelId: 1,
        modelVersionId: 2,
        projectPath: 'path/to/project',
      },
      apolloProvider,
      stubs: {
        LoadOrErrorOrShow,
      },
    });
  };

  const findTitleArea = () => wrapper.findComponent(TitleArea);
  const findModelVersionDetail = () => wrapper.findComponent(ModelVersionDetail);
  const findLoadOrErrorOrShow = () => wrapper.findComponent(LoadOrErrorOrShow);

  it('renders the title', () => {
    createWrapper();

    expect(findTitleArea().props('title')).toBe('blah / 1.2.3');
  });

  it('Requests data with the right parameters', async () => {
    const resolver = jest.fn().mockResolvedValue(modelVersionQuery);

    createWrapper(resolver);

    await waitForPromises();

    expect(resolver).toHaveBeenLastCalledWith(
      expect.objectContaining({
        modelId: 'gid://gitlab/Ml::Model/1',
        modelVersionId: 'gid://gitlab/Ml::ModelVersion/2',
      }),
    );
  });

  it('Displays data when loaded', async () => {
    createWrapper();

    await waitForPromises();

    expect(findModelVersionDetail().props('modelVersion')).toMatchObject(modelVersionWithCandidate);
  });

  it('Shows error message on error', async () => {
    const error = new Error('Failure!');
    createWrapper(jest.fn().mockRejectedValue(error));

    await waitForPromises();

    expect(findLoadOrErrorOrShow().props('errorMessage')).toBe(
      'Failed to load model versions with error: Failure!',
    );
    expect(Sentry.captureException).toHaveBeenCalled();
  });
});

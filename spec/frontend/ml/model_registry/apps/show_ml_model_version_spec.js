import Vue from 'vue';
import { GlIcon, GlSprintf, GlLink } from '@gitlab/ui';
import VueApollo from 'vue-apollo';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import { visitUrlWithAlerts } from '~/lib/utils/url_utility';
import { createAlert } from '~/alert';
import { ShowMlModelVersion } from '~/ml/model_registry/apps';
import ModelVersionDetail from '~/ml/model_registry/components/model_version_detail.vue';
import ModelVersionActionsDropdown from '~/ml/model_registry/components/model_version_actions_dropdown.vue';
import deleteModelVersionMutation from '~/ml/model_registry/graphql/mutations/delete_model_version.mutation.graphql';
import TitleArea from '~/vue_shared/components/registry/title_area.vue';
import LoadOrErrorOrShow from '~/ml/model_registry/components/load_or_error_or_show.vue';
import createMockApollo from 'helpers/mock_apollo_helper';
import getModelVersionQuery from '~/ml/model_registry/graphql/queries/get_model_version.query.graphql';
import waitForPromises from 'helpers/wait_for_promises';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';

import {
  deleteModelVersionResponses,
  modelVersionQueryWithAuthor,
  modelVersionWithCandidateAndAuthor,
} from '../graphql_mock_data';

Vue.use(VueApollo);

jest.mock('~/alert');
jest.mock('~/lib/utils/url_utility', () => ({
  ...jest.requireActual('~/lib/utils/url_utility'),
  visitUrlWithAlerts: jest.fn(),
}));

describe('ml/model_registry/apps/show_model_version.vue', () => {
  let wrapper;
  let apolloProvider;

  beforeEach(() => {
    jest.spyOn(Sentry, 'captureException').mockImplementation();
  });

  afterEach(() => {
    apolloProvider = null;
  });

  const createWrapper = ({
    resolver = jest.fn().mockResolvedValue(modelVersionQueryWithAuthor),
    deleteResolver = jest.fn().mockResolvedValue(deleteModelVersionResponses.success),
    canWriteModelRegistry = true,
  } = {}) => {
    const requestHandlers = [
      [getModelVersionQuery, resolver],
      [deleteModelVersionMutation, deleteResolver],
    ];
    apolloProvider = createMockApollo(requestHandlers);

    wrapper = shallowMountExtended(ShowMlModelVersion, {
      propsData: {
        modelName: 'blah',
        versionName: '1.2.3',
        modelId: 1,
        modelVersionId: 2,
        projectPath: 'path/to/project',
        editModelVersionPath: 'edit/model/version/path',
        canWriteModelRegistry,
        importPath: 'path/to/import',
        modelPath: 'path/to/model',
        maxAllowedFileSize: 99999,
        markdownPreviewPath: 'path/to/preview',
      },
      apolloProvider,
      stubs: {
        LoadOrErrorOrShow,
        GlSprintf,
        GlLink,
        TimeAgoTooltip,
      },
    });
  };

  const findTitleArea = () => wrapper.findComponent(TitleArea);
  const findModelVersionDetail = () => wrapper.findComponent(ModelVersionDetail);
  const findModelVersionActionsDropdown = () => wrapper.findComponent(ModelVersionActionsDropdown);
  const findLoadOrErrorOrShow = () => wrapper.findComponent(LoadOrErrorOrShow);
  const findModelMetadata = () => wrapper.findByTestId('metadata');
  const findTimeAgoTooltip = () => wrapper.findComponent(TimeAgoTooltip);
  const findModelVersionEditButton = () => wrapper.findByTestId('edit-model-version-button');

  it('renders the title', () => {
    createWrapper();

    expect(findTitleArea().props('title')).toBe('blah / 1.2.3');
  });

  describe('Model version edit button', () => {
    beforeEach(() => createWrapper());

    it('displays model version edit button', () => {
      expect(findModelVersionEditButton().props()).toMatchObject({
        variant: 'confirm',
        category: 'primary',
      });
    });

    describe('when user has no permission to write model registry', () => {
      it('does not display model edit button', () => {
        createWrapper({ canWriteModelRegistry: false });
        expect(findModelVersionEditButton().exists()).toBe(false);
      });
    });
  });

  it('Requests data with the right parameters', async () => {
    const resolver = jest.fn().mockResolvedValue(modelVersionQueryWithAuthor);

    createWrapper({ resolver });

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

    expect(findModelVersionDetail().props('modelVersion')).toMatchObject(
      modelVersionWithCandidateAndAuthor,
    );
  });

  it('Show version metadata', async () => {
    createWrapper();

    await waitForPromises();

    expect(findModelMetadata().findComponent(GlIcon).props('name')).toBe('machine-learning');
    expect(findModelMetadata().text()).toBe('Version created in 3 years by Root');

    expect(findTimeAgoTooltip().props('time')).toBe(modelVersionWithCandidateAndAuthor.createdAt);
    expect(findTimeAgoTooltip().props('tooltipPlacement')).toBe('top');

    expect(findModelMetadata().findComponent(GlLink).attributes('href')).toBe('path/to/user');
    expect(findModelMetadata().findComponent(GlLink).text()).toBe('Root');
  });

  it('Shows error message on error', async () => {
    const error = new Error('Failure!');
    createWrapper({ resolver: jest.fn().mockRejectedValue(error) });

    await waitForPromises();

    expect(findLoadOrErrorOrShow().props('errorMessage')).toBe(
      'Failed to load model versions with error: Failure!',
    );
    expect(Sentry.captureException).toHaveBeenCalled();
  });

  it('Makes a delete mutation upon receiving delete-model-version event', async () => {
    createWrapper();

    jest.spyOn(apolloProvider.defaultClient, 'mutate');

    findModelVersionActionsDropdown().vm.$emit('delete-model-version');

    await waitForPromises();

    expect(apolloProvider.defaultClient.mutate).toHaveBeenCalledWith(
      expect.objectContaining({
        mutation: deleteModelVersionMutation,
        variables: {
          id: 'gid://gitlab/Ml::ModelVersion/2',
        },
      }),
    );
  });

  it('Visits the model versions page upon successful delete mutation', async () => {
    createWrapper();

    findModelVersionActionsDropdown().vm.$emit('delete-model-version');

    await waitForPromises();

    expect(visitUrlWithAlerts).toHaveBeenCalledWith('path/to/model#versions', [
      {
        id: 'ml-model-version_deleted-successfully',
        message: 'Model version 1.2.3 deleted successfully',
        variant: 'success',
      },
    ]);
  });

  it('Displays an alert upon failed delete mutation', async () => {
    const failedDeleteResolver = jest.fn().mockResolvedValue(deleteModelVersionResponses.failure);
    createWrapper({ deleteResolver: failedDeleteResolver });

    findModelVersionActionsDropdown().vm.$emit('delete-model-version');

    await waitForPromises();

    expect(createAlert).toHaveBeenCalledWith({
      message:
        'Something went wrong while trying to delete the model version. Please try again later.',
      variant: 'danger',
    });
  });

  it('Logs to sentry upon failed delete mutation', async () => {
    const failedDeleteResolver = jest.fn().mockResolvedValue(deleteModelVersionResponses.failure);
    createWrapper({ deleteResolver: failedDeleteResolver });

    findModelVersionActionsDropdown().vm.$emit('delete-model-version');

    await waitForPromises();

    expect(Sentry.captureException).toHaveBeenCalledWith(
      'Model version not found, Project not found',
      {
        tags: { vue_component: 'show_ml_model_version' },
      },
    );
  });
});

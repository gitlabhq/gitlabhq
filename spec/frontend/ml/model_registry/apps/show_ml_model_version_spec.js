import { GlAvatar, GlBadge, GlTab, GlTabs, GlIcon, GlSprintf, GlLink } from '@gitlab/ui';
import VueRouter from 'vue-router';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { mountExtended, shallowMountExtended } from 'helpers/vue_test_utils_helper';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import { visitUrlWithAlerts } from '~/lib/utils/url_utility';
import { createAlert } from '~/alert';
import { ShowMlModelVersion } from '~/ml/model_registry/apps';
import ModelVersionDetail from '~/ml/model_registry/components/model_version_detail.vue';
import ModelVersionPerformance from '~/ml/model_registry/components/model_version_performance.vue';
import ModelVersionArtifacts from '~/ml/model_registry/components/model_version_artifacts.vue';
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

jest.mock('~/ml/model_registry/components/model_version_detail.vue', () => {
  const { props } = jest.requireActual(
    '~/ml/model_registry/components/model_version_detail.vue',
  ).default;
  return {
    props,
    render() {},
  };
});

jest.mock('~/ml/model_registry/components/model_version_performance.vue', () => {
  const { props } = jest.requireActual(
    '~/ml/model_registry/components/model_version_performance.vue',
  ).default;
  return {
    props,
    render() {},
  };
});

jest.mock('~/ml/model_registry/components/model_version_artifacts.vue', () => {
  const { props } = jest.requireActual(
    '~/ml/model_registry/components/model_version_artifacts.vue',
  ).default;
  return {
    props,
    render() {},
  };
});

jest.mock('~/alert');
jest.mock('~/lib/utils/url_utility', () => ({
  ...jest.requireActual('~/lib/utils/url_utility'),
  visitUrlWithAlerts: jest.fn(),
}));

let wrapper;
let apolloProvider;
describe('ml/model_registry/apps/show_model_version.vue', () => {
  Vue.use(VueApollo);
  Vue.use(VueRouter);

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
    mountFn = shallowMountExtended,
  } = {}) => {
    const requestHandlers = [
      [getModelVersionQuery, resolver],
      [deleteModelVersionMutation, deleteResolver],
    ];
    apolloProvider = createMockApollo(requestHandlers);

    wrapper = mountFn(ShowMlModelVersion, {
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
        GlTab,
        GlBadge,
        GlSprintf,
        GlLink,
        TimeAgoTooltip,
      },
    });

    return waitForPromises();
  };

  const findTitleArea = () => wrapper.findComponent(TitleArea);
  const findModelVersionDetail = () => wrapper.findComponent(ModelVersionDetail);
  const findModelVersionActionsDropdown = () => wrapper.findComponent(ModelVersionActionsDropdown);
  const findLoadOrErrorOrShow = () => wrapper.findComponent(LoadOrErrorOrShow);
  const findModelMetadata = () => wrapper.findByTestId('metadata');
  const findTimeAgoTooltip = () => wrapper.findComponent(TimeAgoTooltip);
  const findModelVersionEditButton = () => wrapper.findByTestId('edit-model-version-button');
  const findTabs = () => wrapper.findComponent(GlTabs);
  const findDetailTab = () => wrapper.findAllComponents(GlTab).at(0);
  const findArtifactsTab = () => wrapper.findAllComponents(GlTab).at(1);
  const findArtifactsCountBadge = () => findArtifactsTab().findComponent(GlBadge);
  const findPerformanceTab = () => wrapper.findAllComponents(GlTab).at(2);
  const findModelVersionPerformance = () => wrapper.findComponent(ModelVersionPerformance);
  const findModelVersionArtifacts = () => wrapper.findComponent(ModelVersionArtifacts);

  it('renders the title', () => {
    createWrapper();

    expect(findTitleArea().props('title')).toBe('blah / 1.2.3');
  });

  describe('Model version edit button', () => {
    beforeEach(() => createWrapper());

    it('displays model version edit button', () => {
      expect(findModelVersionEditButton().props()).toMatchObject({
        variant: 'default',
        category: 'secondary',
      });
      expect(findModelVersionEditButton().text()).toBe('Edit');
    });

    describe('when user has no permission to write model registry', () => {
      it('does not display model edit button', () => {
        createWrapper({ canWriteModelRegistry: false });
        expect(findModelVersionEditButton().exists()).toBe(false);
      });
    });
  });

  describe('Sidebar', () => {
    const findSidebarAuthorLink = () => wrapper.findByTestId('sidebar-author-link');
    const findAvatar = () => wrapper.findComponent(GlAvatar);

    it('displays sidebar author link', async () => {
      const resolver = jest.fn().mockResolvedValue(modelVersionQueryWithAuthor);

      createWrapper({ resolver });

      await waitForPromises();

      expect(findSidebarAuthorLink().attributes('href')).toBe('path/to/user');
      expect(findSidebarAuthorLink().text()).toBe('Root');
      expect(findAvatar().props('src')).toBe('path/to/avatar');
    });

    describe('when model does not get loaded', () => {
      it('does not displays sidebar author link', async () => {
        createWrapper({ resolver: jest.fn().mockRejectedValue(new Error('Failure!')) });
        await waitForPromises();
        expect(findSidebarAuthorLink().exists()).toBe(false);
        expect(wrapper.findByTestId('sidebar-author').text()).toBe('None');
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

  describe('Tabs', () => {
    beforeEach(() => createWrapper());

    it('has a details tab', () => {
      expect(findDetailTab().attributes('title')).toBe('Version card');
    });

    it('shows the number of artifacts in the tab', () => {
      expect(findArtifactsCountBadge().text()).toBe(
        modelVersionWithCandidateAndAuthor.artifactsCount.toString(),
      );
    });

    it('has a performance tab', () => {
      expect(findPerformanceTab().attributes('title')).toBe('Performance');
    });

    it('has an artifacts tab', () => {
      expect(findArtifactsTab().text()).toContain('Artifacts');
    });
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

  describe('Navigation', () => {
    it.each(['#/', '#/unknown-tab'])('shows details when location hash is `%s`', async (path) => {
      await createWrapper({ mountFn: mountExtended });

      await wrapper.vm.$router.push({ path });

      expect(findTabs().props('value')).toBe(0);
      expect(findModelVersionDetail().exists()).toBe(true);
      expect(findModelVersionPerformance().exists()).toBe(false);
      expect(findModelVersionArtifacts().exists()).toBe(false);
    });

    it('shows model details when location hash is default', async () => {
      await createWrapper({ mountFn: mountExtended });

      expect(findTabs().props('value')).toBe(0);
      expect(findModelVersionDetail().props('modelVersion')).toMatchObject(
        modelVersionWithCandidateAndAuthor,
      );
      expect(findModelVersionArtifacts().exists()).toBe(false);
      expect(findModelVersionPerformance().exists()).toBe(false);
    });

    it('shows model artifacts when location hash is `#/artifacts`', async () => {
      await createWrapper({ mountFn: mountExtended });

      await wrapper.vm.$router.push({ path: '/artifacts' });

      expect(findTabs().props('value')).toBe(1);
      expect(findModelVersionDetail().exists()).toBe(false);
      expect(findModelVersionPerformance().exists()).toBe(false);
      expect(findModelVersionArtifacts().props('modelVersion')).toMatchObject(
        modelVersionWithCandidateAndAuthor,
      );
    });

    it('shows model performance when location hash is `#/performance`', async () => {
      await createWrapper({ mountFn: mountExtended });

      await wrapper.vm.$router.push({ path: '/performance' });

      expect(findTabs().props('value')).toBe(2);
      expect(findModelVersionDetail().exists()).toBe(false);
      expect(findModelVersionArtifacts().exists()).toBe(false);
      expect(findModelVersionPerformance().props('modelVersion')).toMatchObject(
        modelVersionWithCandidateAndAuthor,
      );
    });
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
    createWrapper({ resolver: undefined, deleteResolver: failedDeleteResolver });

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
    createWrapper({
      resolver: undefined,
      deleteResolver: failedDeleteResolver,
    });

    findModelVersionActionsDropdown().vm.$emit('delete-model-version');

    await waitForPromises();

    expect(Sentry.captureException).toHaveBeenCalledWith(
      'Model version not found, Project not found',
      {
        tags: { vue_component: 'show_ml_model_version' },
      },
    );
  });

  it('Does not display the edit button when user is not allowed to write', async () => {
    createWrapper({
      resolver: undefined,
      deleteResolver: undefined,
      canWriteModelRegistry: false,
    });
    await waitForPromises();
    expect(findModelVersionEditButton().exists()).toBe(false);
  });

  it('Displays the edit button when user is allowed to write', async () => {
    createWrapper({
      resolve: undefined,
      deleteResolver: undefined,
      canWriteModelRegistry: true,
    });
    await waitForPromises();
    expect(findModelVersionEditButton().exists()).toBe(true);
  });
});

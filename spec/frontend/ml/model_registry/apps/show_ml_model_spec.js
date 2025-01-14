import { GlAvatar, GlBadge, GlTab, GlTabs, GlIcon, GlSprintf, GlLink } from '@gitlab/ui';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import VueRouter from 'vue-router';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import { mountExtended, shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { ShowMlModel } from '~/ml/model_registry/apps';
import ModelVersionList from '~/ml/model_registry/components/model_version_list.vue';
import CandidateList from '~/ml/model_registry/components/candidate_list.vue';
import TitleArea from '~/vue_shared/components/registry/title_area.vue';
import createMockApollo from 'helpers/mock_apollo_helper';
import ModelDetail from '~/ml/model_registry/components/model_detail.vue';
import waitForPromises from 'helpers/wait_for_promises';
import setWindowLocation from 'helpers/set_window_location_helper';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import { visitUrlWithAlerts } from '~/lib/utils/url_utility';
import destroyModelMutation from '~/ml/model_registry/graphql/mutations/destroy_model.mutation.graphql';
import getModelQuery from '~/ml/model_registry/graphql/queries/get_model.query.graphql';
import ActionsDropdown from '~/ml/model_registry/components/actions_dropdown.vue';
import DeleteModelDisclosureDropdownItem from '~/ml/model_registry/components/delete_model_disclosure_dropdown_item.vue';
import DeleteModel from '~/ml/model_registry/components/functional/delete_model.vue';
import LoadOrErrorOrShow from '~/ml/model_registry/components/load_or_error_or_show.vue';
import {
  destroyModelResponses,
  model,
  modelDetailQuery,
  modelWithNoVersionDetailQuery,
} from '../graphql_mock_data';

// Vue Test Utils `stubs` option does not stub components mounted
// in <router-view>. Use mocking instead:
jest.mock('~/ml/model_registry/components/candidate_list.vue', () => {
  const { props } = jest.requireActual('~/ml/model_registry/components/candidate_list.vue').default;
  return {
    props,
    render() {},
  };
});

jest.mock('~/ml/model_registry/components/model_version_list.vue', () => {
  const { props } = jest.requireActual(
    '~/ml/model_registry/components/model_version_list.vue',
  ).default;
  return {
    props,
    render() {},
  };
});

jest.mock('~/ml/model_registry/components/model_detail.vue', () => {
  const { props } = jest.requireActual('~/ml/model_registry/components/model_detail.vue').default;
  return {
    props,
    render() {},
  };
});

jest.mock('~/lib/utils/url_utility', () => ({
  ...jest.requireActual('~/lib/utils/url_utility'),
  visitUrlWithAlerts: jest.fn(),
}));

let apolloProvider;
let wrapper;

describe('ml/model_registry/apps/show_ml_model', () => {
  Vue.use(VueApollo);
  Vue.use(VueRouter);

  beforeEach(() => {
    jest.spyOn(Sentry, 'captureException').mockImplementation();
  });

  const createWrapper = ({
    modelId = 1,
    mountFn = shallowMountExtended,
    modelDetailsResolver = jest.fn().mockResolvedValue(modelDetailQuery),
    destroyMutationResolver = jest.fn().mockResolvedValue(destroyModelResponses.success),
    canWriteModelRegistry = true,
    latestVersion = '1.0.0',
  } = {}) => {
    const requestHandlers = [
      [getModelQuery, modelDetailsResolver],
      [destroyModelMutation, destroyMutationResolver],
    ];
    apolloProvider = createMockApollo(requestHandlers);

    wrapper = mountFn(ShowMlModel, {
      apolloProvider,
      propsData: {
        modelId,
        modelName: 'MyModel',
        projectPath: 'project/path',
        indexModelsPath: 'index/path',
        editModelPath: 'edit/modal/path',
        mlflowTrackingUrl: 'path/to/tracking',
        canWriteModelRegistry,
        maxAllowedFileSize: 99999,
        latestVersion,
        markdownPreviewPath: '/markdown-preview',
        createModelVersionPath: 'project/path/create/model/version',
      },
      stubs: { GlTab, DeleteModel, LoadOrErrorOrShow, GlSprintf, TimeAgoTooltip },
    });

    return waitForPromises();
  };

  const findTabs = () => wrapper.findComponent(GlTabs);
  const findDetailTab = () => wrapper.findAllComponents(GlTab).at(0);
  const findVersionsTab = () => wrapper.findAllComponents(GlTab).at(1);
  const findVersionsCountBadge = () => findVersionsTab().findComponent(GlBadge);
  const findModelVersionList = () => wrapper.findComponent(ModelVersionList);
  const findModelDetail = () => wrapper.findComponent(ModelDetail);
  const findCandidateList = () => wrapper.findComponent(CandidateList);
  const findTitleArea = () => wrapper.findComponent(TitleArea);
  const findModelMetadata = () => wrapper.findByTestId('metadata');
  const findActionsDropdown = () => wrapper.findComponent(ActionsDropdown);
  const findDeleteButton = () => wrapper.findComponent(DeleteModelDisclosureDropdownItem);
  const findDeleteModel = () => wrapper.findComponent(DeleteModel);
  const findModelVersionCreateButton = () => wrapper.findByTestId('model-version-create-button');
  const findLoadOrErrorOrShow = () => wrapper.findComponent(LoadOrErrorOrShow);
  const findModelEditButton = () => wrapper.findByTestId('edit-model-button');
  const findTimeAgoTooltip = () => wrapper.findComponent(TimeAgoTooltip);
  const findCandidateTab = () => wrapper.findAllComponents(GlTab).at(2);
  const findCandidatesCountBadge = () => findCandidateTab().findComponent(GlBadge);

  describe('Title', () => {
    beforeEach(() => createWrapper());

    it('title is set to model name', () => {
      expect(findTitleArea().props('title')).toBe('MyModel');
    });

    it('sets model metadata correctly', () => {
      expect(findModelMetadata().findComponent(GlIcon).props('name')).toBe('machine-learning');
      expect(findModelMetadata().text()).toBe('Model created in 3 years by Root');

      expect(findTimeAgoTooltip().props('time')).toBe(model.createdAt);
      expect(findTimeAgoTooltip().props('tooltipPlacement')).toBe('top');
      expect(findTimeAgoTooltip().vm.tooltipText).toBe('December 6, 2023 at 12:41:48 PM GMT');

      expect(findModelMetadata().findComponent(GlLink).attributes('href')).toBe('path/to/user');
      expect(findModelMetadata().findComponent(GlLink).text()).toBe('Root');
    });

    it('renders the extra actions button', () => {
      expect(findActionsDropdown().exists()).toBe(true);
    });
  });

  describe('Delete button', () => {
    describe('when user has permission to write model registry', () => {
      it('displays delete button', () => {
        createWrapper();

        expect(findDeleteButton().exists()).toBe(true);
      });
    });

    describe('when user has no permission to write model registry', () => {
      it('does not display delete button', () => {
        createWrapper({ canWriteModelRegistry: false });

        expect(findDeleteButton().exists()).toBe(false);
      });
    });
  });

  describe('Model version create button', () => {
    beforeEach(() => createWrapper());

    it('displays version creation button', () => {
      expect(findModelVersionCreateButton().exists()).toBe(true);
      expect(findModelVersionCreateButton().text()).toBe('Create new version');
    });

    describe('when user has no permission to write model registry', () => {
      it('does not display version creation', () => {
        createWrapper({ canWriteModelRegistry: false });

        expect(findModelVersionCreateButton().exists()).toBe(false);
      });
    });
  });

  describe('Model edit button', () => {
    beforeEach(() => createWrapper());

    it('displays model edit button', () => {
      expect(findModelEditButton().props()).toMatchObject({
        category: 'primary',
      });
      expect(findModelEditButton().text()).toBe('Edit');
    });

    describe('when user has no permission to write model registry', () => {
      it('does not display model edit button', () => {
        createWrapper({ canWriteModelRegistry: false });
        expect(findModelEditButton().exists()).toBe(false);
      });
    });
  });

  describe('Tabs', () => {
    beforeEach(() => createWrapper());

    it('has a details tab', () => {
      expect(findDetailTab().attributes('title')).toBe('Model card');
    });

    it('shows the number of versions in the tab', () => {
      expect(findVersionsCountBadge().text()).toBe('1');
    });
  });

  describe('Tabs for model no version', () => {
    beforeEach(() =>
      createWrapper({
        modelDetailsResolver: jest.fn().mockResolvedValue(modelWithNoVersionDetailQuery),
        latestVersion: null,
      }),
    );

    it('does not show badge', () => {
      expect(findVersionsCountBadge().exists()).toBe(false);
    });

    it('shows model card', () => {
      expect(findDetailTab().exists()).toBe(true);
    });

    it('shows the number of candidates in the tab', () => {
      expect(findCandidatesCountBadge().text()).toBe(model.candidateCount.toString());
    });
  });

  describe('Model loading', () => {
    it('displays model detail when query is successful', async () => {
      await createWrapper({ mountFn: mountExtended });

      expect(findModelDetail().props('model')).toMatchObject(model);
    });

    it('shows error when query fails', async () => {
      const error = new Error('Failure!');
      await createWrapper({ modelDetailsResolver: jest.fn().mockRejectedValue(error) });

      expect(findLoadOrErrorOrShow().props('errorMessage')).toBe(
        'Failed to load model with error: Failure!',
      );
      expect(Sentry.captureException).toHaveBeenCalled();
      expect(findModelDetail().exists()).toBe(false);
    });
  });

  describe('Navigation', () => {
    it.each(['#/', '#/unknown-tab'])('shows details when location hash is `%s`', async (path) => {
      await createWrapper({ mountFn: mountExtended });

      await wrapper.vm.$router.push({ path });

      expect(findTabs().props('value')).toBe(0);
      expect(findModelDetail().exists()).toBe(true);
      expect(findModelVersionList().exists()).toBe(false);
      expect(findCandidateList().exists()).toBe(false);
    });

    it('shows model version list when clicks versions tabs', async () => {
      await createWrapper({ mountFn: mountExtended });

      await findVersionsTab().vm.$emit('click');

      expect(findTabs().props('value')).toBe(1);
      expect(findModelDetail().exists()).toBe(false);
      expect(findModelVersionList().props('modelId')).toBe(model.id);
      expect(findCandidateList().exists()).toBe(false);
    });

    it('shows candidate list when user clicks candidates tab', async () => {
      await createWrapper({ mountFn: mountExtended });

      await findCandidateTab().vm.$emit('click');

      expect(findTabs().props('value')).toBe(2);
      expect(findModelDetail().exists()).toBe(false);
      expect(findModelVersionList().exists()).toBe(false);
      expect(findCandidateList().props('modelId')).toBe(model.id);
    });

    describe.each`
      location          | tab                 | navigatedTo
      ${'#/'}           | ${findDetailTab}    | ${0}
      ${'#/'}           | ${findVersionsTab}  | ${1}
      ${'#/'}           | ${findCandidateTab} | ${2}
      ${'#/versions'}   | ${findDetailTab}    | ${0}
      ${'#/versions'}   | ${findVersionsTab}  | ${1}
      ${'#/versions'}   | ${findCandidateTab} | ${2}
      ${'#/candidates'} | ${findDetailTab}    | ${0}
      ${'#/candidates'} | ${findVersionsTab}  | ${1}
      ${'#/candidates'} | ${findCandidateTab} | ${2}
    `('When at $location', ({ location, tab, navigatedTo }) => {
      beforeEach(async () => {
        setWindowLocation(location);

        await createWrapper({
          mountFn: mountExtended,
        });
      });

      it(`on click on ${tab}, navigates to ${JSON.stringify(navigatedTo)}`, async () => {
        await tab().vm.$emit('click');

        expect(findTabs().props('value')).toBe(navigatedTo);
      });
    });
  });

  describe('Model deletion', () => {
    it('sets up DeleteModel', () => {
      createWrapper();

      expect(findDeleteModel().props('modelId')).toBe('gid://gitlab/Ml::Model/1');
    });

    describe('When deletion is successful', () => {
      it('navigates to index page', async () => {
        createWrapper();

        findDeleteModel().vm.$emit('model-deleted');

        await waitForPromises();

        expect(visitUrlWithAlerts).toHaveBeenCalledWith('index/path', [
          expect.objectContaining({ id: 'ml-model-deleted-successfully' }),
        ]);
      });
    });

    describe('When deletion results in error', () => {
      it('shows error message', async () => {
        const destroyMutationResolver = jest.fn().mockResolvedValue(destroyModelResponses.failure);

        createWrapper({ destroyMutationResolver });

        findDeleteButton().vm.$emit('confirm-deletion', { preventDefault: () => {} });

        await waitForPromises();

        expect(visitUrlWithAlerts).not.toHaveBeenCalled();
      });
    });
  });

  describe('Sidebar', () => {
    beforeEach(() => createWrapper());

    const findSidebarAuthorLink = () => wrapper.findByTestId('sidebar-author-link');
    const findAvatar = () => wrapper.findComponent(GlAvatar);
    const findLatestVersionLink = () => wrapper.findByTestId('sidebar-latest-version-link');
    const findVersionCount = () => wrapper.findByTestId('sidebar-version-count');
    const findExperimentTitle = () => wrapper.findByTestId('sidebar-experiment-title');
    const findExperiment = () => wrapper.findByTestId('sidebar-experiment-label');

    it('displays sidebar author link', () => {
      expect(findSidebarAuthorLink().attributes('href')).toBe('path/to/user');
      expect(findSidebarAuthorLink().text()).toBe('Root');
    });

    it('displays sidebar avatar', () => {
      expect(findAvatar().props('src')).toBe('path/to/avatar');
    });

    describe('latest version', () => {
      it('displays sidebar latest version link', () => {
        expect(findLatestVersionLink().attributes('href')).toBe(
          '/root/test-project/-/ml/models/1/versions/5000',
        );
        expect(findLatestVersionLink().text()).toBe('1.0.4999');
      });

      it('does not display sidebar latest version link when model does not have a latest version', () => {
        createWrapper({ latestVersion: null });
        expect(findLatestVersionLink().exists()).toBe(false);
        expect(wrapper.findByTestId('sidebar-latest-version').text()).toBe('None');
      });
    });

    it('displays sidebar version count', () => {
      expect(findVersionCount().text()).toBe('1');
    });

    describe('displays experiment information', () => {
      it('displays experiment title', () => {
        expect(findExperimentTitle().text()).toBe('Experiment');
      });

      it('displays experiment label', () => {
        expect(findExperiment().text()).toBe('Default experiment');
      });

      it('shows a link to the default experiment', () => {
        expect(findExperiment().findComponent(GlLink).attributes('href')).toBe(
          'path/to/experiment',
        );
      });
    });

    describe('when model does not get loaded', () => {
      const error = new Error('Failure!');
      beforeEach(() => createWrapper({ modelDetailsResolver: jest.fn().mockRejectedValue(error) }));

      it('does not display sidebar author link', () => {
        expect(findSidebarAuthorLink().exists()).toBe(false);
      });

      it('does not display sidebar latest version link', () => {
        expect(findLatestVersionLink().exists()).toBe(false);
      });

      it('does not display sidebar version count', () => {
        expect(findVersionCount().text()).toBe('None');
      });

      it('does not display sidebar experiment information', () => {
        expect(findExperimentTitle().exists()).toBe(false);
        expect(findExperiment().exists()).toBe(false);
      });
    });
  });
});

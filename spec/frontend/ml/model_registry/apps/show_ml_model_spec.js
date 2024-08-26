import { GlBadge, GlTab, GlTabs } from '@gitlab/ui';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import VueRouter from 'vue-router';
import { mountExtended, shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { ShowMlModel } from '~/ml/model_registry/apps';
import ModelVersionList from '~/ml/model_registry/components/model_version_list.vue';
import CandidateList from '~/ml/model_registry/components/candidate_list.vue';
import TitleArea from '~/vue_shared/components/registry/title_area.vue';
import MetadataItem from '~/vue_shared/components/registry/metadata_item.vue';
import createMockApollo from 'helpers/mock_apollo_helper';
import ModelVersionCreate from '~/ml/model_registry/components/model_version_create.vue';
import ModelDetail from '~/ml/model_registry/components/model_detail.vue';
import ModelEdit from '~/ml/model_registry/components/model_edit.vue';
import waitForPromises from 'helpers/wait_for_promises';
import setWindowLocation from 'helpers/set_window_location_helper';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import { visitUrlWithAlerts } from '~/lib/utils/url_utility';
import destroyModelMutation from '~/ml/model_registry/graphql/mutations/destroy_model.mutation.graphql';
import getModelQuery from '~/ml/model_registry/graphql/queries/get_model.query.graphql';
import ActionsDropdown from '~/ml/model_registry/components/actions_dropdown.vue';
import DeleteDisclosureDropdownItem from '~/ml/model_registry/components/delete_disclosure_dropdown_item.vue';
import DeleteModel from '~/ml/model_registry/components/functional/delete_model.vue';
import LoadOrErrorOrShow from '~/ml/model_registry/components/load_or_error_or_show.vue';
import { destroyModelResponses, model, modelDetailQuery } from '../graphql_mock_data';

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
        mlflowTrackingUrl: 'path/to/tracking',
        canWriteModelRegistry,
        maxAllowedFileSize: 99999,
        latestVersion: '',
        markdownPreviewPath: '/markdown-preview',
      },
      stubs: { GlTab, DeleteModel, LoadOrErrorOrShow },
    });

    return waitForPromises();
  };

  const findTabs = () => wrapper.findComponent(GlTabs);
  const findDetailTab = () => wrapper.findAllComponents(GlTab).at(0);
  const findVersionsTab = () => wrapper.findAllComponents(GlTab).at(1);
  const findVersionsCountBadge = () => findVersionsTab().findComponent(GlBadge);
  const findModelVersionList = () => wrapper.findComponent(ModelVersionList);
  const findModelDetail = () => wrapper.findComponent(ModelDetail);
  const findCandidateTab = () => wrapper.findAllComponents(GlTab).at(2);
  const findCandidateList = () => wrapper.findComponent(CandidateList);
  const findCandidatesCountBadge = () => findCandidateTab().findComponent(GlBadge);
  const findTitleArea = () => wrapper.findComponent(TitleArea);
  const findVersionCountMetadataItem = () => findTitleArea().findComponent(MetadataItem);
  const findActionsDropdown = () => wrapper.findComponent(ActionsDropdown);
  const findDeleteButton = () => wrapper.findComponent(DeleteDisclosureDropdownItem);
  const findDeleteModel = () => wrapper.findComponent(DeleteModel);
  const findModelVersionCreate = () => wrapper.findComponent(ModelVersionCreate);
  const findLoadOrErrorOrShow = () => wrapper.findComponent(LoadOrErrorOrShow);
  const findModelEdit = () => wrapper.findComponent(ModelEdit);

  describe('Title', () => {
    beforeEach(() => createWrapper());

    it('title is set to model name', () => {
      expect(findTitleArea().props('title')).toBe('MyModel');
    });

    it('sets version metadata item to version count', () => {
      expect(findVersionCountMetadataItem().props('text')).toBe(`${model.versionCount} version`);
    });

    it('renders the extra actions button', () => {
      expect(findActionsDropdown().exists()).toBe(true);
    });
  });

  describe('Delete button', () => {
    describe('when user has permission to write model registry', () => {
      it('displays create button', () => {
        createWrapper();

        expect(findDeleteButton().props('actionPrimaryText')).toBe('Delete model');
      });
    });

    describe('when user has no permission to write model registry', () => {
      it('does not display delete button', () => {
        createWrapper({ canWriteModelRegistry: false });

        expect(findDeleteButton().exists()).toBe(false);
      });
    });
  });

  describe('ModelVersionCreate', () => {
    beforeEach(() => createWrapper());

    it('displays version creation button', () => {
      expect(findModelVersionCreate().props()).toEqual({
        modelGid: 'gid://gitlab/Ml::Model/1',
        disableAttachments: true,
      });
    });

    describe('when user has no permission to write model registry', () => {
      it('does not display version creation', () => {
        createWrapper({ canWriteModelRegistry: false });

        expect(findModelVersionCreate().exists()).toBe(false);
      });
    });
  });

  describe('ModelEdit', () => {
    beforeEach(() => createWrapper());

    it('displays model edit button', () => {
      expect(findModelEdit().props('model')).toEqual(model);
      expect(findModelEdit().props('disableAttachments')).toBe(true);
    });

    describe('when user has no permission to write model registry', () => {
      it('does not display model edit button', () => {
        createWrapper({ canWriteModelRegistry: false });
        expect(findModelEdit().exists()).toBe(false);
      });
    });
  });

  describe('Tabs', () => {
    beforeEach(() => createWrapper());

    it('has a details tab', () => {
      expect(findDetailTab().attributes('title')).toBe('Model card');
    });

    it('shows the number of versions in the tab', () => {
      expect(findVersionsCountBadge().text()).toBe(model.versionCount.toString());
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

    it('shows model version list when location hash is `#/versions`', async () => {
      await createWrapper({ mountFn: mountExtended });

      await wrapper.vm.$router.push({ path: '/versions' });

      expect(findTabs().props('value')).toBe(1);
      expect(findModelDetail().exists()).toBe(false);
      expect(findModelVersionList().props('modelId')).toBe(model.id);
      expect(findCandidateList().exists()).toBe(false);
    });

    it('shows candidate list when location hash is `#/candidates`', async () => {
      await createWrapper({ mountFn: mountExtended });

      await findCandidateTab().vm.$emit('click');

      expect(findTabs().props('value')).toBe(2);
      expect(findModelDetail().exists()).toBe(false);
      expect(findModelVersionList().exists()).toBe(false);
      expect(findCandidateList().props('modelId')).toBe(model.id);
    });

    describe.each`
      location        | tab                | navigatedTo
      ${'#/'}         | ${findDetailTab}   | ${0}
      ${'#/'}         | ${findVersionsTab} | ${1}
      ${'#/versions'} | ${findDetailTab}   | ${0}
      ${'#/versions'} | ${findVersionsTab} | ${1}
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
});

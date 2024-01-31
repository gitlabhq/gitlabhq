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
import ModelDetail from '~/ml/model_registry/components/model_detail.vue';
import waitForPromises from 'helpers/wait_for_promises';
import setWindowLocation from 'helpers/set_window_location_helper';
import { MODEL } from '../mock_data';

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

const apolloProvider = createMockApollo([]);
let wrapper;

describe('ml/model_registry/apps/show_ml_model', () => {
  Vue.use(VueApollo);
  Vue.use(VueRouter);

  const createWrapper = ({ model = MODEL, mountFn = shallowMountExtended } = {}) => {
    wrapper = mountFn(ShowMlModel, {
      apolloProvider,
      propsData: { model },
      stubs: { GlTab },
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

  describe('Title', () => {
    beforeEach(() => createWrapper());

    it('title is set to model name', () => {
      expect(findTitleArea().props('title')).toBe(MODEL.name);
    });

    it('subheader is set to description', () => {
      expect(findTitleArea().text()).toContain(MODEL.description);
    });

    it('sets version metadata item to version count', () => {
      expect(findVersionCountMetadataItem().props('text')).toBe(`${MODEL.versionCount} versions`);
    });
  });

  describe('Tabs', () => {
    beforeEach(() => createWrapper());

    it('has a details tab', () => {
      expect(findDetailTab().attributes('title')).toBe('Details');
    });

    it('shows the number of versions in the tab', () => {
      expect(findVersionsCountBadge().text()).toBe(MODEL.versionCount.toString());
    });

    it('shows the number of candidates in the tab', () => {
      expect(findCandidatesCountBadge().text()).toBe(MODEL.candidateCount.toString());
    });
  });

  describe('Navigation', () => {
    it.each(['#/', '#/unknown-tab'])('shows details when location hash is `%s`', async (path) => {
      createWrapper({ mountFn: mountExtended });
      await wrapper.vm.$router.push({ path });

      expect(findTabs().props('value')).toBe(0);
      expect(findModelDetail().props('model')).toBe(MODEL);
      expect(findModelVersionList().exists()).toBe(false);
      expect(findCandidateList().exists()).toBe(false);
    });

    it('shows model version list when location hash is `#/versions`', async () => {
      await createWrapper({ mountFn: mountExtended });

      await wrapper.vm.$router.push({ path: '/versions' });

      expect(findTabs().props('value')).toBe(1);
      expect(findModelDetail().exists()).toBe(false);
      expect(findModelVersionList().props('modelId')).toBe(MODEL.id);
      expect(findCandidateList().exists()).toBe(false);
    });

    it('shows candidate list when location hash is `#/candidates`', async () => {
      await createWrapper({ mountFn: mountExtended });

      await findCandidateTab().vm.$emit('click');

      expect(findTabs().props('value')).toBe(2);
      expect(findModelDetail().exists()).toBe(false);
      expect(findModelVersionList().exists()).toBe(false);
      expect(findCandidateList().props('modelId')).toBe(MODEL.id);
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
});

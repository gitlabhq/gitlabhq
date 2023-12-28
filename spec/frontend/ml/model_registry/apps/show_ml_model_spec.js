import { GlBadge, GlTab } from '@gitlab/ui';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { ShowMlModel } from '~/ml/model_registry/apps';
import ModelVersionList from '~/ml/model_registry/components/model_version_list.vue';
import CandidateList from '~/ml/model_registry/components/candidate_list.vue';
import ModelVersionDetail from '~/ml/model_registry/components/model_version_detail.vue';
import EmptyState from '~/ml/model_registry/components/empty_state.vue';
import TitleArea from '~/vue_shared/components/registry/title_area.vue';
import MetadataItem from '~/vue_shared/components/registry/metadata_item.vue';
import createMockApollo from 'helpers/mock_apollo_helper';
import { MODEL_ENTITIES } from '~/ml/model_registry/constants';
import { MODEL, makeModel } from '../mock_data';

const apolloProvider = createMockApollo([]);
let wrapper;

Vue.use(VueApollo);

const createWrapper = (model = MODEL) => {
  wrapper = shallowMountExtended(ShowMlModel, {
    apolloProvider,
    propsData: { model },
    stubs: { GlTab },
  });
};

const findDetailTab = () => wrapper.findAllComponents(GlTab).at(0);
const findVersionsTab = () => wrapper.findAllComponents(GlTab).at(1);
const findVersionsCountBadge = () => findVersionsTab().findComponent(GlBadge);
const findModelVersionList = () => findVersionsTab().findComponent(ModelVersionList);
const findModelVersionDetail = () => findDetailTab().findComponent(ModelVersionDetail);
const findCandidateTab = () => wrapper.findAllComponents(GlTab).at(2);
const findCandidateList = () => findCandidateTab().findComponent(CandidateList);
const findCandidatesCountBadge = () => findCandidateTab().findComponent(GlBadge);
const findTitleArea = () => wrapper.findComponent(TitleArea);
const findEmptyState = () => wrapper.findComponent(EmptyState);
const findVersionCountMetadataItem = () => findTitleArea().findComponent(MetadataItem);
const findVersionLink = () => wrapper.findByTestId('model-version-link');

describe('ShowMlModel', () => {
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

  describe('Details', () => {
    beforeEach(() => createWrapper());

    it('has a details tab', () => {
      expect(findDetailTab().attributes('title')).toBe('Details');
    });

    describe('when it has latest version', () => {
      it('displays the version', () => {
        expect(findModelVersionDetail().props('modelVersion')).toBe(MODEL.latestVersion);
      });

      it('displays a link to latest version', () => {
        expect(findDetailTab().text()).toContain('Latest version:');
        expect(findVersionLink().attributes('href')).toBe(MODEL.latestVersion.path);
        expect(findVersionLink().text()).toBe('1.2.3');
      });
    });

    describe('when it does not have latest version', () => {
      beforeEach(() => {
        createWrapper(makeModel({ latestVersion: null }));
      });

      it('shows empty state', () => {
        expect(findEmptyState().props('entityType')).toBe(MODEL_ENTITIES.modelVersion);
      });

      it('does not render model version detail', () => {
        expect(findModelVersionDetail().exists()).toBe(false);
      });
    });
  });

  describe('Versions tab', () => {
    beforeEach(() => createWrapper());

    it('shows the number of versions in the tab', () => {
      expect(findVersionsCountBadge().text()).toBe(MODEL.versionCount.toString());
    });

    it('shows a list of model versions', () => {
      expect(findModelVersionList().props('modelId')).toBe(MODEL.id);
    });
  });

  describe('Candidates tab', () => {
    beforeEach(() => createWrapper());

    it('shows the number of candidates in the tab', () => {
      expect(findCandidatesCountBadge().text()).toBe(MODEL.candidateCount.toString());
    });

    it('shows a list of candidates', () => {
      expect(findCandidateList().props('modelId')).toBe(MODEL.id);
    });
  });
});

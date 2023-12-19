import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import ModelVersionDetail from '~/ml/model_registry/components/model_version_detail.vue';
import PackageFiles from '~/packages_and_registries/package_registry/components/details/package_files.vue';
import CandidateDetail from '~/ml/model_registry/components/candidate_detail.vue';
import createMockApollo from 'helpers/mock_apollo_helper';
import { makeModelVersion, MODEL_VERSION } from '../mock_data';

Vue.use(VueApollo);

let wrapper;
const createWrapper = (modelVersion = MODEL_VERSION) => {
  const apolloProvider = createMockApollo([]);
  wrapper = shallowMount(ModelVersionDetail, { apolloProvider, propsData: { modelVersion } });
};

const findPackageFiles = () => wrapper.findComponent(PackageFiles);
const findCandidateDetail = () => wrapper.findComponent(CandidateDetail);

describe('ml/model_registry/components/model_version_detail.vue', () => {
  describe('base behaviour', () => {
    beforeEach(() => createWrapper());

    it('shows the description', () => {
      expect(wrapper.text()).toContain(MODEL_VERSION.description);
    });

    it('shows the candidate', () => {
      expect(findCandidateDetail().props('candidate')).toBe(MODEL_VERSION.candidate);
    });

    it('shows the mlflow label string', () => {
      expect(wrapper.text()).toContain('MLflow run ID');
    });

    it('shows the mlflow id', () => {
      expect(wrapper.text()).toContain(MODEL_VERSION.candidate.info.eid);
    });

    it('renders files', () => {
      expect(findPackageFiles().props()).toEqual({
        packageId: 'gid://gitlab/Packages::Package/12',
        projectPath: MODEL_VERSION.projectPath,
        packageType: 'ml_model',
        canDelete: false,
      });
    });
  });

  describe('if package does not exist', () => {
    beforeEach(() => createWrapper(makeModelVersion({ packageId: 0 })));

    it('does not render files', () => {
      expect(findPackageFiles().exists()).toBe(false);
    });
  });

  describe('if model version does not have description', () => {
    beforeEach(() => createWrapper(makeModelVersion({ description: null })));

    it('renders no description provided label', () => {
      expect(wrapper.text()).toContain('No description provided');
    });
  });
});

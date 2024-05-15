import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import ModelVersionDetail from '~/ml/model_registry/components/model_version_detail.vue';
import PackageFiles from '~/packages_and_registries/package_registry/components/details/package_files.vue';
import CandidateDetail from '~/ml/model_registry/components/candidate_detail.vue';
import createMockApollo from 'helpers/mock_apollo_helper';
import { convertCandidateFromGraphql } from '~/ml/model_registry/utils';
import { modelVersionWithCandidate } from '../graphql_mock_data';

Vue.use(VueApollo);

const makeGraphqlModelVersion = (overrides = {}) => {
  return { ...modelVersionWithCandidate, ...overrides };
};

let wrapper;
const createWrapper = (modelVersion = modelVersionWithCandidate) => {
  const apolloProvider = createMockApollo([]);
  wrapper = shallowMount(ModelVersionDetail, {
    apolloProvider,
    propsData: { modelVersion },
    provide: {
      projectPath: 'path/to/project',
      canWriteModelRegistry: true,
    },
  });
};

const findPackageFiles = () => wrapper.findComponent(PackageFiles);
const findCandidateDetail = () => wrapper.findComponent(CandidateDetail);

describe('ml/model_registry/components/model_version_detail.vue', () => {
  describe('base behaviour', () => {
    beforeEach(() => createWrapper());

    it('shows the description', () => {
      expect(wrapper.text()).toContain('A model version description');
    });

    it('shows the candidate', () => {
      expect(findCandidateDetail().props('candidate')).toMatchObject(
        convertCandidateFromGraphql(modelVersionWithCandidate.candidate),
      );
    });

    it('shows the mlflow label string', () => {
      expect(wrapper.text()).toContain('MLflow run ID');
    });

    it('shows the mlflow id', () => {
      expect(wrapper.text()).toContain(modelVersionWithCandidate.candidate.eid);
    });

    it('renders files', () => {
      expect(findPackageFiles().props()).toEqual({
        packageId: 'gid://gitlab/Packages::Package/12',
        projectPath: 'path/to/project',
        packageType: 'ml_model',
        canDelete: true,
        deleteAllFiles: true,
      });
    });
  });

  describe('if package does not exist', () => {
    beforeEach(() => createWrapper(makeGraphqlModelVersion({ packageId: 0 })));

    it('does not render files', () => {
      expect(findPackageFiles().exists()).toBe(false);
    });
  });

  describe('if model version does not have description', () => {
    beforeEach(() => createWrapper(makeGraphqlModelVersion({ description: null })));

    it('renders no description provided label', () => {
      expect(wrapper.text()).toContain('No description provided');
    });
  });
});

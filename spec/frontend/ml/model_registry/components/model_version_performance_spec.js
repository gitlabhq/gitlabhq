import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { GlIcon, GlButton, GlLink } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import ModelVersionPerformance from '~/ml/model_registry/components/model_version_performance.vue';
import CandidateDetail from '~/ml/model_registry/components/candidate_detail.vue';
import createMockApollo from 'helpers/mock_apollo_helper';
import { convertCandidateFromGraphql } from '~/ml/model_registry/utils';
import getPackageFiles from '~/packages_and_registries/package_registry/graphql/queries/get_package_files.query.graphql';
import { packageFilesQuery } from 'jest/packages_and_registries/package_registry/mock_data';
import { modelVersionWithCandidate } from '../graphql_mock_data';

Vue.use(VueApollo);

let wrapper;
const createWrapper = (modelVersion = modelVersionWithCandidate, props = {}, provide = {}) => {
  const requestHandlers = [
    [getPackageFiles, jest.fn().mockResolvedValue(packageFilesQuery({ files: [] }))],
  ];

  const apolloProvider = createMockApollo(requestHandlers);
  wrapper = shallowMountExtended(ModelVersionPerformance, {
    apolloProvider,
    propsData: {
      allowArtifactImport: true,
      modelVersion,
      ...props,
    },
    provide: {
      projectPath: 'path/to/project',
      canWriteModelRegistry: true,
      importPath: 'path/to/import',
      maxAllowedFileSize: 99999,
      ...provide,
    },
    stubs: {
      GlButton,
      GlIcon,
    },
  });
};

const findCandidateDetail = () => wrapper.findComponent(CandidateDetail);
const findCopyMlflowIdButton = () => wrapper.findComponent(GlButton);
const findCandidateLink = () => wrapper.findComponent(GlLink);

describe('ml/model_registry/components/model_version_detail.vue', () => {
  describe('base behaviour', () => {
    beforeEach(() => createWrapper());

    it('shows the candidate', () => {
      expect(findCandidateDetail().props('candidate')).toMatchObject(
        convertCandidateFromGraphql(modelVersionWithCandidate.candidate),
      );
    });

    it('shows the copy mlflow id button', () => {
      expect(findCopyMlflowIdButton().exists()).toBe(true);
      expect(findCopyMlflowIdButton().props('icon')).toBe('copy-to-clipboard');
      expect(findCopyMlflowIdButton().findComponent(GlIcon).props('name')).toBe(
        'copy-to-clipboard',
      );
    });

    it('shows the mlflow label string', () => {
      expect(wrapper.text()).toContain('MLflow run ID');
    });

    it('shows the mlflow id', () => {
      expect(wrapper.text()).toContain(modelVersionWithCandidate.candidate.eid);
    });

    it('links to candidate', () => {
      expect(findCandidateLink().attributes('href')).toBe(
        modelVersionWithCandidate.candidate._links.showPath,
      );
    });
  });
});

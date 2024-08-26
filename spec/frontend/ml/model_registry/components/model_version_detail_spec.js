import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import ModelVersionDetail from '~/ml/model_registry/components/model_version_detail.vue';
import PackageFiles from '~/packages_and_registries/package_registry/components/details/package_files.vue';
import CandidateDetail from '~/ml/model_registry/components/candidate_detail.vue';
import ImportArtifactZone from '~/ml/model_registry/components/import_artifact_zone.vue';
import createMockApollo from 'helpers/mock_apollo_helper';
import { convertCandidateFromGraphql } from '~/ml/model_registry/utils';
import getPackageFiles from '~/packages_and_registries/package_registry/graphql/queries/get_package_files.query.graphql';
import { packageFilesQuery } from 'jest/packages_and_registries/package_registry/mock_data';
import { modelVersionWithCandidate } from '../graphql_mock_data';

Vue.use(VueApollo);

const makeGraphqlModelVersion = (overrides = {}) => {
  return { ...modelVersionWithCandidate, ...overrides };
};

let wrapper;
const createWrapper = (modelVersion = modelVersionWithCandidate, props = {}, provide = {}) => {
  const requestHandlers = [
    [getPackageFiles, jest.fn().mockResolvedValue(packageFilesQuery({ files: [] }))],
  ];

  const apolloProvider = createMockApollo(requestHandlers);
  wrapper = shallowMountExtended(ModelVersionDetail, {
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
  });
};

const findPackageFiles = () => wrapper.findComponent(PackageFiles);
const findCandidateDetail = () => wrapper.findComponent(CandidateDetail);
const findImportArtifactZone = () => wrapper.findComponent(ImportArtifactZone);
const artifactLabel = () => wrapper.findByTestId('uploadHeader');
const findDescription = () => wrapper.findByTestId('description');
const findEmptyDescriptionState = () => wrapper.findByTestId('emptyDescriptionState');

describe('ml/model_registry/components/model_version_detail.vue', () => {
  describe('base behaviour', () => {
    beforeEach(() => createWrapper());

    it('shows the description', () => {
      expect(findDescription().props('issuable')).toMatchObject({
        descriptionHtml: 'A model version description',
        titleHtml: undefined,
      });
      expect(findEmptyDescriptionState().exists()).toBe(false);
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

    it('renders import artifact zone', () => {
      expect(findImportArtifactZone().props()).toEqual({
        path: 'path/to/import',
        submitOnSelect: true,
        value: {
          file: null,
          subfolder: '',
        },
      });
    });

    it('renders artifact label', () => {
      expect(artifactLabel().text()).toContain('Upload artifacts');
    });
  });

  describe('if package does not exist', () => {
    beforeEach(() => createWrapper(makeGraphqlModelVersion({ packageId: 0 })));

    it('does not render files', () => {
      expect(findPackageFiles().exists()).toBe(false);
    });
  });

  describe('if permission does not exist', () => {
    beforeEach(() => createWrapper(undefined, undefined, { canWriteModelRegistry: false }));

    it('does not render import artifact zone', () => {
      expect(findImportArtifactZone().exists()).toBe(false);
    });
  });

  describe('if import path does not exist', () => {
    beforeEach(() => createWrapper(undefined, undefined, { importPath: undefined }));

    it('does not render import artifact zone', () => {
      expect(findImportArtifactZone().exists()).toBe(false);
    });
  });

  describe('if artifact import is not allowed', () => {
    beforeEach(() => createWrapper(undefined, { allowArtifactImport: false }));

    it('does not render import artifact zone', () => {
      expect(findImportArtifactZone().exists()).toBe(false);
    });
  });

  describe('if model version does not have description', () => {
    beforeEach(() =>
      createWrapper(makeGraphqlModelVersion({ description: null, descriptionHtml: null })),
    );

    it('renders no description provided label', () => {
      expect(findDescription().exists()).toBe(false);
      expect(findEmptyDescriptionState().exists()).toBe(true);
      expect(findEmptyDescriptionState().text()).toContain('No description provided');
    });
  });
});

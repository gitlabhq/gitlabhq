import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import ModelVersionArtifacts from '~/ml/model_registry/components/model_version_artifacts.vue';
import PackageFiles from '~/packages_and_registries/package_registry/components/details/package_files.vue';
import ImportArtifactZone from '~/ml/model_registry/components/import_artifact_zone.vue';
import createMockApollo from 'helpers/mock_apollo_helper';
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
  wrapper = shallowMountExtended(ModelVersionArtifacts, {
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
      PackageFiles,
    },
  });
};

const findPackageFiles = () => wrapper.findComponent(PackageFiles);
const findImportArtifactZone = () => wrapper.findComponent(ImportArtifactZone);
const artifactLabel = () => wrapper.findByTestId('uploadHeader');

describe('ml/model_registry/components/model_version_detail.vue', () => {
  describe('base behaviour', () => {
    beforeEach(() => createWrapper());

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
});

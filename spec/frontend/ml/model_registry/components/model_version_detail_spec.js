import { shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import ModelVersionDetail from '~/ml/model_registry/components/model_version_detail.vue';
import PackageFiles from '~/packages_and_registries/package_registry/components/details/package_files.vue';
import createMockApollo from 'helpers/mock_apollo_helper';
import { makeModelVersion, MODEL_VERSION } from '../mock_data';

Vue.use(VueApollo);

let wrapper;
const createWrapper = (modelVersion = MODEL_VERSION) => {
  const apolloProvider = createMockApollo([]);
  wrapper = shallowMount(ModelVersionDetail, { apolloProvider, propsData: { modelVersion } });
};

const findPackageFiles = () => wrapper.findComponent(PackageFiles);

describe('ml/model_registry/components/model_version_detail.vue', () => {
  describe('description', () => {
    beforeEach(() => createWrapper());

    it('shows the description', () => {
      expect(wrapper.text()).toContain(MODEL_VERSION.description);
    });
  });

  describe('package files', () => {
    describe('if package exists', () => {
      beforeEach(() => createWrapper());

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
  });
});

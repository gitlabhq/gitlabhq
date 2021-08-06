import { nextTick } from 'vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';

import { packageData } from 'jest/packages_and_registries/package_registry/mock_data';
import InstallationTitle from '~/packages_and_registries/package_registry/components/details/installation_title.vue';
import NpmInstallation from '~/packages_and_registries/package_registry/components/details/npm_installation.vue';
import {
  TRACKING_ACTION_COPY_NPM_INSTALL_COMMAND,
  TRACKING_ACTION_COPY_NPM_SETUP_COMMAND,
  TRACKING_ACTION_COPY_YARN_INSTALL_COMMAND,
  TRACKING_ACTION_COPY_YARN_SETUP_COMMAND,
  PACKAGE_TYPE_NPM,
  NPM_PACKAGE_MANAGER,
  YARN_PACKAGE_MANAGER,
} from '~/packages_and_registries/package_registry/constants';
import CodeInstructions from '~/vue_shared/components/registry/code_instruction.vue';

const packageEntity = { ...packageData(), packageType: PACKAGE_TYPE_NPM };

describe('NpmInstallation', () => {
  let wrapper;

  const npmInstallationCommandLabel = 'npm i @gitlab-org/package-15';
  const yarnInstallationCommandLabel = 'yarn add @gitlab-org/package-15';

  const findCodeInstructions = () => wrapper.findAllComponents(CodeInstructions);
  const findInstallationTitle = () => wrapper.findComponent(InstallationTitle);

  function createComponent({ data = {} } = {}) {
    wrapper = shallowMountExtended(NpmInstallation, {
      provide: {
        npmHelpPath: 'npmHelpPath',
        npmPath: 'npmPath',
      },
      propsData: {
        packageEntity,
      },
      data() {
        return data;
      },
    });
  }

  beforeEach(() => {
    createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('renders all the messages', () => {
    expect(wrapper.element).toMatchSnapshot();
  });

  describe('install command switch', () => {
    it('has the installation title component', () => {
      expect(findInstallationTitle().exists()).toBe(true);
      expect(findInstallationTitle().props()).toMatchObject({
        packageType: NPM_PACKAGE_MANAGER,
        options: [
          { value: NPM_PACKAGE_MANAGER, label: 'Show NPM commands' },
          { value: YARN_PACKAGE_MANAGER, label: 'Show Yarn commands' },
        ],
      });
    });

    it('on change event updates the instructions to show', async () => {
      createComponent();

      expect(findCodeInstructions().at(0).props('instruction')).toBe(npmInstallationCommandLabel);
      findInstallationTitle().vm.$emit('change', YARN_PACKAGE_MANAGER);

      await nextTick();

      expect(findCodeInstructions().at(0).props('instruction')).toBe(yarnInstallationCommandLabel);
    });
  });

  describe('npm', () => {
    beforeEach(() => {
      createComponent();
    });
    it('renders the correct installation command', () => {
      expect(findCodeInstructions().at(0).props()).toMatchObject({
        instruction: npmInstallationCommandLabel,
        multiline: false,
        trackingAction: TRACKING_ACTION_COPY_NPM_INSTALL_COMMAND,
      });
    });

    it('renders the correct setup command', () => {
      expect(findCodeInstructions().at(1).props()).toMatchObject({
        instruction: 'echo @gitlab-org:registry=npmPath/ >> .npmrc',
        multiline: false,
        trackingAction: TRACKING_ACTION_COPY_NPM_SETUP_COMMAND,
      });
    });
  });

  describe('yarn', () => {
    beforeEach(() => {
      createComponent({ data: { instructionType: YARN_PACKAGE_MANAGER } });
    });

    it('renders the correct setup command', () => {
      expect(findCodeInstructions().at(0).props()).toMatchObject({
        instruction: yarnInstallationCommandLabel,
        multiline: false,
        trackingAction: TRACKING_ACTION_COPY_YARN_INSTALL_COMMAND,
      });
    });

    it('renders the correct registry command', () => {
      expect(findCodeInstructions().at(1).props()).toMatchObject({
        instruction: 'echo \\"@gitlab-org:registry\\" \\"npmPath/\\" >> .yarnrc',
        multiline: false,
        trackingAction: TRACKING_ACTION_COPY_YARN_SETUP_COMMAND,
      });
    });
  });
});

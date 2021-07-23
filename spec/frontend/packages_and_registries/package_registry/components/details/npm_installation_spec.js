import { shallowMount, createLocalVue } from '@vue/test-utils';
import { nextTick } from 'vue';
import Vuex from 'vuex';
import { registryUrl as nugetPath } from 'jest/packages/details/mock_data';
import { npmPackage as packageEntity } from 'jest/packages/mock_data';
import { TrackingActions } from '~/packages/details/constants';
import { npmInstallationCommand, npmSetupCommand } from '~/packages/details/store/getters';
import InstallationTitle from '~/packages_and_registries/package_registry/components/details/installation_title.vue';
import NpmInstallation from '~/packages_and_registries/package_registry/components/details/npm_installation.vue';
import CodeInstructions from '~/vue_shared/components/registry/code_instruction.vue';

const localVue = createLocalVue();
localVue.use(Vuex);

describe('NpmInstallation', () => {
  let wrapper;

  const npmInstallationCommandLabel = 'npm i @Test/package';
  const yarnInstallationCommandLabel = 'yarn add @Test/package';

  const findCodeInstructions = () => wrapper.findAll(CodeInstructions);
  const findInstallationTitle = () => wrapper.findComponent(InstallationTitle);

  function createComponent({ data = {} } = {}) {
    const store = new Vuex.Store({
      state: {
        packageEntity,
        nugetPath,
      },
      getters: {
        npmInstallationCommand,
        npmSetupCommand,
      },
    });

    wrapper = shallowMount(NpmInstallation, {
      localVue,
      store,
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
        packageType: 'npm',
        options: [
          { value: 'npm', label: 'Show NPM commands' },
          { value: 'yarn', label: 'Show Yarn commands' },
        ],
      });
    });

    it('on change event updates the instructions to show', async () => {
      createComponent();

      expect(findCodeInstructions().at(0).props('instruction')).toBe(npmInstallationCommandLabel);
      findInstallationTitle().vm.$emit('change', 'yarn');

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
        trackingAction: TrackingActions.COPY_NPM_INSTALL_COMMAND,
      });
    });

    it('renders the correct setup command', () => {
      expect(findCodeInstructions().at(1).props()).toMatchObject({
        instruction: 'echo @Test:registry=undefined/ >> .npmrc',
        multiline: false,
        trackingAction: TrackingActions.COPY_NPM_SETUP_COMMAND,
      });
    });
  });

  describe('yarn', () => {
    beforeEach(() => {
      createComponent({ data: { instructionType: 'yarn' } });
    });

    it('renders the correct setup command', () => {
      expect(findCodeInstructions().at(0).props()).toMatchObject({
        instruction: yarnInstallationCommandLabel,
        multiline: false,
        trackingAction: TrackingActions.COPY_YARN_INSTALL_COMMAND,
      });
    });

    it('renders the correct registry command', () => {
      expect(findCodeInstructions().at(1).props()).toMatchObject({
        instruction: 'echo \\"@Test:registry\\" \\"undefined/\\" >> .yarnrc',
        multiline: false,
        trackingAction: TrackingActions.COPY_YARN_SETUP_COMMAND,
      });
    });
  });
});

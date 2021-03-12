import { shallowMount, createLocalVue } from '@vue/test-utils';
import Vuex from 'vuex';
import { registryUrl as nugetPath } from 'jest/packages/details/mock_data';
import { nugetPackage as packageEntity } from 'jest/packages/mock_data';
import InstallationTitle from '~/packages/details/components/installation_title.vue';
import NugetInstallation from '~/packages/details/components/nuget_installation.vue';
import { TrackingActions } from '~/packages/details/constants';
import CodeInstructions from '~/vue_shared/components/registry/code_instruction.vue';

const localVue = createLocalVue();
localVue.use(Vuex);

describe('NugetInstallation', () => {
  let wrapper;

  const nugetInstallationCommandStr = 'foo/command';
  const nugetSetupCommandStr = 'foo/setup';

  const store = new Vuex.Store({
    state: {
      packageEntity,
      nugetPath,
    },
    getters: {
      nugetInstallationCommand: () => nugetInstallationCommandStr,
      nugetSetupCommand: () => nugetSetupCommandStr,
    },
  });

  const findCodeInstructions = () => wrapper.findAll(CodeInstructions);
  const findInstallationTitle = () => wrapper.findComponent(InstallationTitle);

  function createComponent() {
    wrapper = shallowMount(NugetInstallation, {
      localVue,
      store,
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
        packageType: 'nuget',
        options: [{ value: 'nuget', label: 'Show Nuget commands' }],
      });
    });
  });

  describe('installation commands', () => {
    it('renders the correct command', () => {
      expect(findCodeInstructions().at(0).props()).toMatchObject({
        instruction: nugetInstallationCommandStr,
        trackingAction: TrackingActions.COPY_NUGET_INSTALL_COMMAND,
      });
    });
  });

  describe('setup commands', () => {
    it('renders the correct command', () => {
      expect(findCodeInstructions().at(1).props()).toMatchObject({
        instruction: nugetSetupCommandStr,
        trackingAction: TrackingActions.COPY_NUGET_SETUP_COMMAND,
      });
    });
  });
});

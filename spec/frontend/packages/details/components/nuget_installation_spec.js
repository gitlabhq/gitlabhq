import Vuex from 'vuex';
import { shallowMount, createLocalVue } from '@vue/test-utils';
import { nugetPackage as packageEntity } from 'jest/packages/mock_data';
import { registryUrl as nugetPath } from 'jest/packages/details/mock_data';
import NugetInstallation from '~/packages/details/components/nuget_installation.vue';
import CodeInstructions from '~/vue_shared/components/registry/code_instruction.vue';
import { TrackingActions } from '~/packages/details/constants';

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
    if (wrapper) wrapper.destroy();
  });

  it('renders all the messages', () => {
    expect(wrapper.element).toMatchSnapshot();
  });

  describe('installation commands', () => {
    it('renders the correct command', () => {
      expect(
        findCodeInstructions()
          .at(0)
          .props(),
      ).toMatchObject({
        instruction: nugetInstallationCommandStr,
        trackingAction: TrackingActions.COPY_NUGET_INSTALL_COMMAND,
      });
    });
  });

  describe('setup commands', () => {
    it('renders the correct command', () => {
      expect(
        findCodeInstructions()
          .at(1)
          .props(),
      ).toMatchObject({
        instruction: nugetSetupCommandStr,
        trackingAction: TrackingActions.COPY_NUGET_SETUP_COMMAND,
      });
    });
  });
});

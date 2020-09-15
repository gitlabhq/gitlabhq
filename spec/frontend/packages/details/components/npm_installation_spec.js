import Vuex from 'vuex';
import { shallowMount, createLocalVue } from '@vue/test-utils';
import { npmPackage as packageEntity } from 'jest/packages/mock_data';
import { registryUrl as nugetPath } from 'jest/packages/details/mock_data';
import NpmInstallation from '~/packages/details/components/npm_installation.vue';
import CodeInstructions from '~/vue_shared/components/registry/code_instruction.vue';
import { TrackingActions } from '~/packages/details/constants';
import { npmInstallationCommand, npmSetupCommand } from '~/packages/details/store/getters';

const localVue = createLocalVue();
localVue.use(Vuex);

describe('NpmInstallation', () => {
  let wrapper;

  const findCodeInstructions = () => wrapper.findAll(CodeInstructions);

  function createComponent() {
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
    it('renders the correct npm command', () => {
      expect(
        findCodeInstructions()
          .at(0)
          .props(),
      ).toMatchObject({
        instruction: 'npm i @Test/package',
        multiline: false,
        trackingAction: TrackingActions.COPY_NPM_INSTALL_COMMAND,
      });
    });

    it('renders the correct yarn command', () => {
      expect(
        findCodeInstructions()
          .at(1)
          .props(),
      ).toMatchObject({
        instruction: 'yarn add @Test/package',
        multiline: false,
        trackingAction: TrackingActions.COPY_YARN_INSTALL_COMMAND,
      });
    });
  });

  describe('setup commands', () => {
    it('renders the correct npm command', () => {
      expect(
        findCodeInstructions()
          .at(2)
          .props(),
      ).toMatchObject({
        instruction: 'echo @Test:registry=undefined/ >> .npmrc',
        multiline: false,
        trackingAction: TrackingActions.COPY_NPM_SETUP_COMMAND,
      });
    });

    it('renders the correct yarn command', () => {
      expect(
        findCodeInstructions()
          .at(3)
          .props(),
      ).toMatchObject({
        instruction: 'echo \\"@Test:registry\\" \\"undefined/\\" >> .yarnrc',
        multiline: false,
        trackingAction: TrackingActions.COPY_YARN_SETUP_COMMAND,
      });
    });
  });
});

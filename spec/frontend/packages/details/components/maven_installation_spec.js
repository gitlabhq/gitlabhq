import Vuex from 'vuex';
import { shallowMount, createLocalVue } from '@vue/test-utils';
import { registryUrl as mavenPath } from 'jest/packages/details/mock_data';
import { mavenPackage as packageEntity } from 'jest/packages/mock_data';
import MavenInstallation from '~/packages/details/components/maven_installation.vue';
import CodeInstructions from '~/vue_shared/components/registry/code_instruction.vue';
import { TrackingActions } from '~/packages/details/constants';

const localVue = createLocalVue();
localVue.use(Vuex);

describe('MavenInstallation', () => {
  let wrapper;

  const xmlCodeBlock = 'foo/xml';
  const mavenCommandStr = 'foo/command';
  const mavenSetupXml = 'foo/setup';

  const store = new Vuex.Store({
    state: {
      packageEntity,
      mavenPath,
    },
    getters: {
      mavenInstallationXml: () => xmlCodeBlock,
      mavenInstallationCommand: () => mavenCommandStr,
      mavenSetupXml: () => mavenSetupXml,
    },
  });

  const findCodeInstructions = () => wrapper.findAll(CodeInstructions);

  function createComponent() {
    wrapper = shallowMount(MavenInstallation, {
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
    it('renders the correct xml block', () => {
      expect(
        findCodeInstructions()
          .at(0)
          .props(),
      ).toMatchObject({
        instruction: xmlCodeBlock,
        multiline: true,
        trackingAction: TrackingActions.COPY_MAVEN_XML,
      });
    });

    it('renders the correct maven command', () => {
      expect(
        findCodeInstructions()
          .at(1)
          .props(),
      ).toMatchObject({
        instruction: mavenCommandStr,
        multiline: false,
        trackingAction: TrackingActions.COPY_MAVEN_COMMAND,
      });
    });
  });

  describe('setup commands', () => {
    it('renders the correct xml block', () => {
      expect(
        findCodeInstructions()
          .at(2)
          .props(),
      ).toMatchObject({
        instruction: mavenSetupXml,
        multiline: true,
        trackingAction: TrackingActions.COPY_MAVEN_SETUP,
      });
    });
  });
});

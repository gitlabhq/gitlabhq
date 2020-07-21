import Vuex from 'vuex';
import { mount, createLocalVue } from '@vue/test-utils';
import MavenInstallation from '~/packages/details/components/maven_installation.vue';
import { registryUrl as mavenPath } from '../mock_data';
import { mavenPackage as packageEntity } from '../../mock_data';
import { GlTabs } from '@gitlab/ui';

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

  const findTabs = () => wrapper.find(GlTabs);
  const xmlCode = () => wrapper.find('.js-maven-xml > pre');
  const mavenCommand = () => wrapper.find('.js-maven-command > input');
  const xmlSetup = () => wrapper.find('.js-maven-setup-xml > pre');

  function createComponent() {
    wrapper = mount(MavenInstallation, {
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

  describe('it renders', () => {
    it('with GlTabs', () => {
      expect(findTabs().exists()).toBe(true);
    });
  });

  describe('installation commands', () => {
    it('renders the correct xml block', () => {
      expect(xmlCode().text()).toBe(xmlCodeBlock);
    });

    it('renders the correct maven command', () => {
      expect(mavenCommand().element.value).toBe(mavenCommandStr);
    });
  });

  describe('setup commands', () => {
    it('renders the correct xml block', () => {
      expect(xmlSetup().text()).toBe(mavenSetupXml);
    });
  });
});

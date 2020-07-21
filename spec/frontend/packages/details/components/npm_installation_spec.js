import Vuex from 'vuex';
import { mount, createLocalVue } from '@vue/test-utils';
import NpmInstallation from '~/packages/details/components/npm_installation.vue';
import { npmPackage as packageEntity } from '../../mock_data';
import { registryUrl as nugetPath } from '../mock_data';
import { GlTabs } from '@gitlab/ui';

const localVue = createLocalVue();
localVue.use(Vuex);

describe('NpmInstallation', () => {
  let wrapper;

  const npmCommandStr = 'npm install';
  const npmSetupStr = 'npm setup';
  const yarnCommandStr = 'npm install';
  const yarnSetupStr = 'npm setup';

  const findTabs = () => wrapper.find(GlTabs);
  const npmInstallationCommand = () => wrapper.find('.js-npm-install > input');
  const npmSetupCommand = () => wrapper.find('.js-npm-setup > input');
  const yarnInstallationCommand = () => wrapper.find('.js-yarn-install > input');
  const yarnSetupCommand = () => wrapper.find('.js-yarn-setup > input');

  function createComponent(yarn = false) {
    const store = new Vuex.Store({
      state: {
        packageEntity,
        nugetPath,
      },
      getters: {
        npmInstallationCommand: () => () => (yarn ? yarnCommandStr : npmCommandStr),
        npmSetupCommand: () => () => (yarn ? yarnSetupStr : npmSetupStr),
      },
    });

    wrapper = mount(NpmInstallation, {
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

  describe('npm commands', () => {
    it('renders the correct install command', () => {
      expect(npmInstallationCommand().element.value).toBe(npmCommandStr);
    });

    it('renders the correct setup command', () => {
      expect(npmSetupCommand().element.value).toBe(npmSetupStr);
    });
  });

  describe('yarn commands', () => {
    beforeEach(() => {
      createComponent(true);
    });

    it('renders the correct install command', () => {
      expect(yarnInstallationCommand().element.value).toBe(yarnCommandStr);
    });

    it('renders the correct setup command', () => {
      expect(yarnSetupCommand().element.value).toBe(yarnSetupStr);
    });
  });
});

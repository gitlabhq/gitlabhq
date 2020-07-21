import Vuex from 'vuex';
import { mount, createLocalVue } from '@vue/test-utils';
import NugetInstallation from '~/packages/details/components/nuget_installation.vue';
import { nugetPackage as packageEntity } from '../../mock_data';
import { registryUrl as nugetPath } from '../mock_data';
import { GlTabs } from '@gitlab/ui';

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

  const findTabs = () => wrapper.find(GlTabs);
  const nugetInstallationCommand = () => wrapper.find('.js-nuget-command > input');
  const nugetSetupCommand = () => wrapper.find('.js-nuget-setup > input');

  function createComponent() {
    wrapper = mount(NugetInstallation, {
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
    it('renders the correct command', () => {
      expect(nugetInstallationCommand().element.value).toBe(nugetInstallationCommandStr);
    });
  });

  describe('setup commands', () => {
    it('renders the correct command', () => {
      expect(nugetSetupCommand().element.value).toBe(nugetSetupCommandStr);
    });
  });
});

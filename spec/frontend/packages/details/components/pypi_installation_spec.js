import Vuex from 'vuex';
import { shallowMount, createLocalVue } from '@vue/test-utils';
import PypiInstallation from '~/packages/details/components/pypi_installation.vue';
import InstallationTabs from '~/packages/details/components/installation_tabs.vue';
import { pypiPackage as packageEntity } from '../../mock_data';
import { GlTabs } from '@gitlab/ui';

const localVue = createLocalVue();
localVue.use(Vuex);

describe('PypiInstallation', () => {
  let wrapper;

  const pipCommandStr = 'pip install';
  const pypiSetupStr = 'python setup';

  const store = new Vuex.Store({
    state: {
      packageEntity,
      pypiHelpPath: 'foo',
    },
    getters: {
      pypiPipCommand: () => pipCommandStr,
      pypiSetupCommand: () => pypiSetupStr,
    },
  });

  const findTabs = () => wrapper.find(GlTabs);
  const pipCommand = () => wrapper.find('[data-testid="pip-command"]');
  const setupInstruction = () => wrapper.find('[data-testid="pypi-setup-content"]');

  function createComponent() {
    wrapper = shallowMount(PypiInstallation, {
      localVue,
      store,
      stubs: {
        InstallationTabs,
      },
    });
  }

  beforeEach(() => {
    createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('it renders', () => {
    it('with GlTabs', () => {
      expect(findTabs().exists()).toBe(true);
    });
  });

  describe('installation commands', () => {
    it('renders the correct pip command', () => {
      expect(pipCommand().props('instruction')).toBe(pipCommandStr);
    });
  });

  describe('setup commands', () => {
    it('renders the correct setup block', () => {
      expect(setupInstruction().props('instruction')).toBe(pypiSetupStr);
    });
  });
});

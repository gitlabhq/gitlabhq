import { shallowMount, createLocalVue } from '@vue/test-utils';
import Vuex from 'vuex';
import { pypiPackage as packageEntity } from 'jest/packages/mock_data';
import InstallationTitle from '~/packages/details/components/installation_title.vue';
import PypiInstallation from '~/packages/details/components/pypi_installation.vue';

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

  const pipCommand = () => wrapper.find('[data-testid="pip-command"]');
  const setupInstruction = () => wrapper.find('[data-testid="pypi-setup-content"]');

  const findInstallationTitle = () => wrapper.findComponent(InstallationTitle);

  function createComponent() {
    wrapper = shallowMount(PypiInstallation, {
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

  describe('install command switch', () => {
    it('has the installation title component', () => {
      expect(findInstallationTitle().exists()).toBe(true);
      expect(findInstallationTitle().props()).toMatchObject({
        packageType: 'pypi',
        options: [{ value: 'pypi', label: 'Show PyPi commands' }],
      });
    });
  });

  it('renders all the messages', () => {
    expect(wrapper.element).toMatchSnapshot();
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

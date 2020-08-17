import Vuex from 'vuex';
import { shallowMount, createLocalVue } from '@vue/test-utils';
import { pypiPackage as packageEntity } from 'jest/packages/mock_data';
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
    wrapper = null;
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

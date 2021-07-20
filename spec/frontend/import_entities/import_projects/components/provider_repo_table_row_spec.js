import { GlBadge, GlButton, GlDropdown } from '@gitlab/ui';
import { createLocalVue, shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
import Vuex from 'vuex';
import { STATUSES } from '~/import_entities//constants';
import ImportGroupDropdown from '~/import_entities/components/group_dropdown.vue';
import ImportStatus from '~/import_entities/components/import_status.vue';
import ProviderRepoTableRow from '~/import_entities/import_projects/components/provider_repo_table_row.vue';

describe('ProviderRepoTableRow', () => {
  let wrapper;
  const fetchImport = jest.fn();
  const setImportTarget = jest.fn();
  const fakeImportTarget = {
    targetNamespace: 'target',
    newName: 'newName',
  };

  const availableNamespaces = ['test'];
  const userNamespace = 'root';

  function initStore(initialState) {
    const store = new Vuex.Store({
      state: initialState,
      getters: {
        getImportTarget: () => () => fakeImportTarget,
      },
      actions: { fetchImport, setImportTarget },
    });

    return store;
  }

  const findImportButton = () => {
    const buttons = wrapper.findAllComponents(GlButton).filter((node) => node.text() === 'Import');

    return buttons.length ? buttons.at(0) : buttons;
  };

  function mountComponent(props) {
    const localVue = createLocalVue();
    localVue.use(Vuex);

    const store = initStore();

    wrapper = shallowMount(ProviderRepoTableRow, {
      localVue,
      store,
      propsData: { availableNamespaces, userNamespace, ...props },
    });
  }

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('when rendering importable project', () => {
    const repo = {
      importSource: {
        id: 'remote-1',
        fullName: 'fullName',
        providerLink: 'providerLink',
      },
    };

    beforeEach(() => {
      mountComponent({ repo });
    });

    it('renders project information', () => {
      const providerLink = wrapper.find('[data-testid=providerLink]');

      expect(providerLink.attributes().href).toMatch(repo.importSource.providerLink);
      expect(providerLink.text()).toMatch(repo.importSource.fullName);
    });

    it('renders empty import status', () => {
      expect(wrapper.find(ImportStatus).props().status).toBe(STATUSES.NONE);
    });

    it('renders a group namespace select', () => {
      expect(wrapper.find(ImportGroupDropdown).props().namespaces).toBe(availableNamespaces);
    });

    it('renders import button', () => {
      expect(findImportButton().exists()).toBe(true);
    });

    it('imports repo when clicking import button', async () => {
      findImportButton().vm.$emit('click');

      await nextTick();

      const { calls } = fetchImport.mock;

      expect(calls).toHaveLength(1);
      expect(calls[0][1]).toBe(repo.importSource.id);
    });
  });

  describe('when rendering imported project', () => {
    const repo = {
      importSource: {
        id: 'remote-1',
        fullName: 'fullName',
        providerLink: 'providerLink',
      },
      importedProject: {
        id: 1,
        fullPath: 'fullPath',
        importSource: 'importSource',
        importStatus: STATUSES.FINISHED,
      },
    };

    beforeEach(() => {
      mountComponent({ repo });
    });

    it('renders project information', () => {
      const providerLink = wrapper.find('[data-testid=providerLink]');

      expect(providerLink.attributes().href).toMatch(repo.importSource.providerLink);
      expect(providerLink.text()).toMatch(repo.importSource.fullName);
    });

    it('renders proper import status', () => {
      expect(wrapper.find(ImportStatus).props().status).toBe(repo.importedProject.importStatus);
    });

    it('does not renders a namespace select', () => {
      expect(wrapper.find(GlDropdown).exists()).toBe(false);
    });

    it('does not render import button', () => {
      expect(findImportButton().exists()).toBe(false);
    });
  });

  describe('when rendering incompatible project', () => {
    const repo = {
      importSource: {
        id: 'remote-1',
        fullName: 'fullName',
        providerLink: 'providerLink',
        incompatible: true,
      },
    };

    beforeEach(() => {
      mountComponent({ repo });
    });

    it('renders project information', () => {
      const providerLink = wrapper.find('[data-testid=providerLink]');

      expect(providerLink.attributes().href).toMatch(repo.importSource.providerLink);
      expect(providerLink.text()).toMatch(repo.importSource.fullName);
    });

    it('renders badge with error', () => {
      expect(wrapper.find(GlBadge).text()).toBe('Incompatible project');
    });
  });
});

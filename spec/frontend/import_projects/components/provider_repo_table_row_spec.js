import { nextTick } from 'vue';
import Vuex from 'vuex';
import { createLocalVue, shallowMount } from '@vue/test-utils';
import ProviderRepoTableRow from '~/import_projects/components/provider_repo_table_row.vue';
import ImportStatus from '~/import_projects/components/import_status.vue';
import { STATUSES } from '~/import_projects/constants';
import Select2Select from '~/vue_shared/components/select2_select.vue';

describe('ProviderRepoTableRow', () => {
  let wrapper;
  const fetchImport = jest.fn();
  const setImportTarget = jest.fn();
  const fakeImportTarget = {
    targetNamespace: 'target',
    newName: 'newName',
  };
  const ciCdOnly = false;
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
    },
    importStatus: STATUSES.FINISHED,
  };

  const availableNamespaces = [
    { text: 'Groups', children: [{ id: 'test', text: 'test' }] },
    { text: 'Users', children: [{ id: 'root', text: 'root' }] },
  ];

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

  const findImportButton = () =>
    wrapper
      .findAll('button')
      .filter(node => node.text() === 'Import')
      .at(0);

  function mountComponent(initialState) {
    const localVue = createLocalVue();
    localVue.use(Vuex);

    const store = initStore({ ciCdOnly, ...initialState });

    wrapper = shallowMount(ProviderRepoTableRow, {
      localVue,
      store,
      propsData: { repo, availableNamespaces },
    });
  }

  beforeEach(() => {
    mountComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('renders a provider repo table row', () => {
    const providerLink = wrapper.find('[data-testid=providerLink]');

    expect(providerLink.attributes().href).toMatch(repo.importSource.providerLink);
    expect(providerLink.text()).toMatch(repo.importSource.fullName);
    expect(wrapper.find(ImportStatus).props().status).toBe(repo.importStatus);
    expect(wrapper.contains('button')).toBe(true);
  });

  it('renders a select2 namespace select', () => {
    expect(wrapper.contains(Select2Select)).toBe(true);
    expect(wrapper.find(Select2Select).props().options.data).toBe(availableNamespaces);
  });

  it('imports repo when clicking import button', async () => {
    findImportButton().trigger('click');

    await nextTick();

    const { calls } = fetchImport.mock;

    expect(calls).toHaveLength(1);
    expect(calls[0][1]).toBe(repo.importSource.id);
  });
});

import { GlLoadingIcon, GlButton, GlIntersectionObserver, GlFormInput } from '@gitlab/ui';
import { createLocalVue, shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
import Vuex from 'vuex';
import { STATUSES } from '~/import_entities/constants';
import ImportProjectsTable from '~/import_entities/import_projects/components/import_projects_table.vue';
import ProviderRepoTableRow from '~/import_entities/import_projects/components/provider_repo_table_row.vue';
import * as getters from '~/import_entities/import_projects/store/getters';
import state from '~/import_entities/import_projects/store/state';

describe('ImportProjectsTable', () => {
  let wrapper;

  const USER_NAMESPACE = 'root';

  const findFilterField = () =>
    wrapper
      .findAllComponents(GlFormInput)
      .wrappers.find((w) => w.attributes('placeholder') === 'Filter your repositories by name');

  const providerTitle = 'THE PROVIDER';
  const providerRepo = {
    importSource: {
      id: 10,
      sanitizedName: 'sanitizedName',
      fullName: 'fullName',
    },
    importedProject: null,
  };

  const findImportAllButton = () =>
    wrapper
      .findAll(GlButton)
      .filter((w) => w.props().variant === 'success')
      .at(0);
  const findImportAllModal = () => wrapper.find({ ref: 'importAllModal' });

  const importAllFn = jest.fn();
  const importAllModalShowFn = jest.fn();
  const fetchReposFn = jest.fn();

  function createComponent({
    state: initialState,
    getters: customGetters,
    slots,
    filterable,
    paginatable,
  } = {}) {
    const localVue = createLocalVue();
    localVue.use(Vuex);

    const store = new Vuex.Store({
      state: { ...state(), defaultTargetNamespace: USER_NAMESPACE, ...initialState },
      getters: {
        ...getters,
        ...customGetters,
      },
      actions: {
        fetchRepos: fetchReposFn,
        fetchJobs: jest.fn(),
        fetchNamespaces: jest.fn(),
        importAll: importAllFn,
        stopJobsPolling: jest.fn(),
        clearJobsEtagPoll: jest.fn(),
        setFilter: jest.fn(),
      },
    });

    wrapper = shallowMount(ImportProjectsTable, {
      localVue,
      store,
      propsData: {
        providerTitle,
        filterable,
        paginatable,
      },
      slots,
      stubs: {
        GlModal: { template: '<div>Modal!</div>', methods: { show: importAllModalShowFn } },
      },
    });
  }

  afterEach(() => {
    if (wrapper) {
      wrapper.destroy();
      wrapper = null;
    }
  });

  it('renders a loading icon while repos are loading', () => {
    createComponent({ state: { isLoadingRepos: true } });

    expect(wrapper.find(GlLoadingIcon).exists()).toBe(true);
  });

  it('renders a loading icon while namespaces are loading', () => {
    createComponent({ state: { isLoadingNamespaces: true } });

    expect(wrapper.find(GlLoadingIcon).exists()).toBe(true);
  });

  it('renders a table with provider repos', () => {
    const repositories = [
      { importSource: { id: 1 }, importedProject: null },
      { importSource: { id: 2 }, importedProject: { importStatus: STATUSES.FINISHED } },
      { importSource: { id: 3, incompatible: true }, importedProject: {} },
    ];

    createComponent({
      state: { namespaces: [{ fullPath: 'path' }], repositories },
    });

    expect(wrapper.find(GlLoadingIcon).exists()).toBe(false);
    expect(wrapper.find('table').exists()).toBe(true);
    expect(
      wrapper
        .findAll('th')
        .filter((w) => w.text() === `From ${providerTitle}`)
        .exists(),
    ).toBe(true);

    expect(wrapper.findAll(ProviderRepoTableRow)).toHaveLength(repositories.length);
  });

  it.each`
    hasIncompatibleRepos | count | buttonText
    ${false}             | ${1}  | ${'Import 1 repository'}
    ${true}              | ${1}  | ${'Import 1 compatible repository'}
    ${false}             | ${5}  | ${'Import 5 repositories'}
    ${true}              | ${5}  | ${'Import 5 compatible repositories'}
  `(
    'import all button has "$buttonText" text when hasIncompatibleRepos is $hasIncompatibleRepos and repos count is $count',
    ({ hasIncompatibleRepos, buttonText, count }) => {
      createComponent({
        state: {
          providerRepos: [providerRepo],
        },
        getters: {
          hasIncompatibleRepos: () => hasIncompatibleRepos,
          importAllCount: () => count,
        },
      });

      expect(findImportAllButton().text()).toBe(buttonText);
    },
  );

  it.each`
    importingRepoCount | buttonMessage
    ${1}               | ${'Importing 1 repository'}
    ${5}               | ${'Importing 5 repositories'}
  `(
    'sets the button text to "$buttonMessage" when importing repos',
    ({ importingRepoCount, buttonMessage }) => {
      createComponent({
        state: {
          providerRepos: [providerRepo],
        },
        getters: {
          hasIncompatibleRepos: () => false,
          importAllCount: () => 10,
          isImportingAnyRepo: () => true,
          importingRepoCount: () => importingRepoCount,
        },
      });

      expect(findImportAllButton().text()).toBe(buttonMessage);
    },
  );

  it('renders an empty state if there are no repositories available', () => {
    createComponent({ state: { repositories: [] } });

    expect(wrapper.find(ProviderRepoTableRow).exists()).toBe(false);
    expect(wrapper.text()).toContain(`No ${providerTitle} repositories found`);
  });

  it('opens confirmation modal when import all button is clicked', async () => {
    createComponent({ state: { repositories: [providerRepo] } });

    findImportAllButton().vm.$emit('click');
    await nextTick();

    expect(importAllModalShowFn).toHaveBeenCalled();
  });

  it('triggers importAll action when modal is confirmed', async () => {
    createComponent({ state: { providerRepos: [providerRepo] } });

    findImportAllModal().vm.$emit('ok');
    await nextTick();

    expect(importAllFn).toHaveBeenCalled();
  });

  it('shows loading spinner when import is in progress', () => {
    createComponent({ getters: { isImportingAnyRepo: () => true, importallCount: () => 1 } });

    expect(findImportAllButton().props().loading).toBe(true);
  });

  it('renders filtering input field by default', () => {
    createComponent();

    expect(findFilterField().exists()).toBe(true);
  });

  it('does not render filtering input field when filterable is false', () => {
    createComponent({ filterable: false });

    expect(findFilterField()).toBeUndefined();
  });

  describe('when paginatable is set to true', () => {
    const pageInfo = { page: 1 };

    beforeEach(() => {
      createComponent({
        state: {
          namespaces: [{ fullPath: 'path' }],
          pageInfo,
          repositories: [
            { importSource: { id: 1 }, importedProject: null, importStatus: STATUSES.NONE },
          ],
        },
        paginatable: true,
      });
    });

    it('does not call fetchRepos on mount', () => {
      expect(fetchReposFn).not.toHaveBeenCalled();
    });

    it('renders intersection observer component', () => {
      expect(wrapper.find(GlIntersectionObserver).exists()).toBe(true);
    });

    it('calls fetchRepos when intersection observer appears', async () => {
      wrapper.find(GlIntersectionObserver).vm.$emit('appear');

      await nextTick();

      expect(fetchReposFn).toHaveBeenCalled();
    });
  });

  it('calls fetchRepos on mount', () => {
    createComponent();

    expect(fetchReposFn).toHaveBeenCalled();
  });

  it.each`
    hasIncompatibleRepos | shouldRenderSlot | action
    ${false}             | ${false}         | ${'does not render'}
    ${true}              | ${true}          | ${'render'}
  `(
    '$action incompatible-repos-warning slot if hasIncompatibleRepos is $hasIncompatibleRepos',
    ({ hasIncompatibleRepos, shouldRenderSlot }) => {
      const INCOMPATIBLE_TEXT = 'INCOMPATIBLE!';

      createComponent({
        getters: {
          hasIncompatibleRepos: () => hasIncompatibleRepos,
        },

        slots: {
          'incompatible-repos-warning': INCOMPATIBLE_TEXT,
        },
      });

      expect(wrapper.text().includes(INCOMPATIBLE_TEXT)).toBe(shouldRenderSlot);
    },
  );
});

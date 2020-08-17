import { nextTick } from 'vue';
import Vuex from 'vuex';
import { createLocalVue, shallowMount } from '@vue/test-utils';
import { GlLoadingIcon, GlButton } from '@gitlab/ui';
import state from '~/import_projects/store/state';
import * as getters from '~/import_projects/store/getters';
import { STATUSES } from '~/import_projects/constants';
import ImportProjectsTable from '~/import_projects/components/import_projects_table.vue';
import ImportedProjectTableRow from '~/import_projects/components/imported_project_table_row.vue';
import ProviderRepoTableRow from '~/import_projects/components/provider_repo_table_row.vue';
import IncompatibleRepoTableRow from '~/import_projects/components/incompatible_repo_table_row.vue';

describe('ImportProjectsTable', () => {
  let wrapper;

  const findFilterField = () =>
    wrapper.find('input[data-qa-selector="githubish_import_filter_field"]');

  const providerTitle = 'THE PROVIDER';
  const providerRepo = { id: 10, sanitizedName: 'sanitizedName', fullName: 'fullName' };

  const findImportAllButton = () =>
    wrapper
      .findAll(GlButton)
      .filter(w => w.props().variant === 'success')
      .at(0);

  const importAllFn = jest.fn();
  function createComponent({
    state: initialState,
    getters: customGetters,
    slots,
    filterable,
  } = {}) {
    const localVue = createLocalVue();
    localVue.use(Vuex);

    const store = new Vuex.Store({
      state: { ...state(), ...initialState },
      getters: {
        ...getters,
        ...customGetters,
      },
      actions: {
        fetchRepos: jest.fn(),
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
      },
      slots,
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

    expect(wrapper.contains(GlLoadingIcon)).toBe(true);
  });

  it('renders a loading icon while namespaces are loading', () => {
    createComponent({ state: { isLoadingNamespaces: true } });

    expect(wrapper.contains(GlLoadingIcon)).toBe(true);
  });

  it('renders a table with imported projects and provider repos', () => {
    createComponent({
      state: {
        namespaces: [{ fullPath: 'path' }],
        repositories: [
          { importSource: { id: 1 }, importedProject: null, importStatus: STATUSES.NONE },
          { importSource: { id: 2 }, importedProject: {}, importStatus: STATUSES.FINISHED },
          {
            importSource: { id: 3, incompatible: true },
            importedProject: {},
            importStatus: STATUSES.NONE,
          },
        ],
      },
    });

    expect(wrapper.contains(GlLoadingIcon)).toBe(false);
    expect(wrapper.contains('table')).toBe(true);
    expect(
      wrapper
        .findAll('th')
        .filter(w => w.text() === `From ${providerTitle}`)
        .isEmpty(),
    ).toBe(false);

    expect(wrapper.contains(ProviderRepoTableRow)).toBe(true);
    expect(wrapper.contains(ImportedProjectTableRow)).toBe(true);
    expect(wrapper.contains(IncompatibleRepoTableRow)).toBe(true);
  });

  it.each`
    hasIncompatibleRepos | buttonText
    ${false}             | ${'Import all repositories'}
    ${true}              | ${'Import all compatible repositories'}
  `(
    'import all button has "$buttonText" text when hasIncompatibleRepos is $hasIncompatibleRepos',
    ({ hasIncompatibleRepos, buttonText }) => {
      createComponent({
        state: {
          providerRepos: [providerRepo],
        },
        getters: {
          hasIncompatibleRepos: () => hasIncompatibleRepos,
        },
      });

      expect(findImportAllButton().text()).toBe(buttonText);
    },
  );

  it('renders an empty state if there are no projects available', () => {
    createComponent({ state: { repositories: [] } });

    expect(wrapper.contains(ProviderRepoTableRow)).toBe(false);
    expect(wrapper.contains(ImportedProjectTableRow)).toBe(false);
    expect(wrapper.text()).toContain(`No ${providerTitle} repositories found`);
  });

  it('sends importAll event when import button is clicked', async () => {
    createComponent({ state: { providerRepos: [providerRepo] } });

    findImportAllButton().vm.$emit('click');
    await nextTick();

    expect(importAllFn).toHaveBeenCalled();
  });

  it('shows loading spinner when import is in progress', () => {
    createComponent({ getters: { isImportingAnyRepo: () => true } });

    expect(findImportAllButton().props().loading).toBe(true);
  });

  it('renders filtering input field by default', () => {
    createComponent();

    expect(findFilterField().exists()).toBe(true);
  });

  it('does not render filtering input field when filterable is false', () => {
    createComponent({ filterable: false });

    expect(findFilterField().exists()).toBe(false);
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

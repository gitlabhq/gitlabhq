import Vuex from 'vuex';
import { createLocalVue, mount } from '@vue/test-utils';
import { state, actions, getters, mutations } from '~/import_projects/store';
import importProjectsTable from '~/import_projects/components/import_projects_table.vue';
import STATUS_MAP from '~/import_projects/constants';

describe('ImportProjectsTable', () => {
  let vm;
  const providerTitle = 'THE PROVIDER';
  const providerRepo = { id: 10, sanitizedName: 'sanitizedName', fullName: 'fullName' };
  const importedProject = {
    id: 1,
    fullPath: 'fullPath',
    importStatus: 'started',
    providerLink: 'providerLink',
    importSource: 'importSource',
  };

  function initStore() {
    const stubbedActions = Object.assign({}, actions, {
      fetchJobs: jest.fn(),
      fetchRepos: jest.fn(actions.requestRepos),
      fetchImport: jest.fn(actions.requestImport),
    });

    const store = new Vuex.Store({
      state: state(),
      actions: stubbedActions,
      mutations,
      getters,
    });

    return store;
  }

  function mountComponent() {
    const localVue = createLocalVue();
    localVue.use(Vuex);

    const store = initStore();

    const component = mount(importProjectsTable, {
      localVue,
      store,
      propsData: {
        providerTitle,
      },
    });

    return component.vm;
  }

  beforeEach(() => {
    vm = mountComponent();
  });

  afterEach(() => {
    vm.$destroy();
  });

  it('renders a loading icon whilst repos are loading', () =>
    vm.$nextTick().then(() => {
      expect(vm.$el.querySelector('.js-loading-button-icon')).not.toBeNull();
    }));

  it('renders a table with imported projects and provider repos', () => {
    vm.$store.dispatch('receiveReposSuccess', {
      importedProjects: [importedProject],
      providerRepos: [providerRepo],
      namespaces: [{ path: 'path' }],
    });

    return vm.$nextTick().then(() => {
      expect(vm.$el.querySelector('.js-loading-button-icon')).toBeNull();
      expect(vm.$el.querySelector('.table')).not.toBeNull();
      expect(vm.$el.querySelector('.import-jobs-from-col').innerText).toMatch(
        `From ${providerTitle}`,
      );

      expect(vm.$el.querySelector('.js-imported-project')).not.toBeNull();
      expect(vm.$el.querySelector('.js-provider-repo')).not.toBeNull();
    });
  });

  it('renders an empty state if there are no imported projects or provider repos', () => {
    vm.$store.dispatch('receiveReposSuccess', {
      importedProjects: [],
      providerRepos: [],
      namespaces: [],
    });

    return vm.$nextTick().then(() => {
      expect(vm.$el.querySelector('.js-loading-button-icon')).toBeNull();
      expect(vm.$el.querySelector('.table')).toBeNull();
      expect(vm.$el.innerText).toMatch(`No ${providerTitle} repositories found`);
    });
  });

  it('shows loading spinner when bulk import button is clicked', () => {
    vm.$store.dispatch('receiveReposSuccess', {
      importedProjects: [],
      providerRepos: [providerRepo],
      namespaces: [{ path: 'path' }],
    });

    return vm
      .$nextTick()
      .then(() => {
        expect(vm.$el.querySelector('.js-imported-project')).toBeNull();
        expect(vm.$el.querySelector('.js-provider-repo')).not.toBeNull();

        vm.$el.querySelector('.js-import-all').click();
      })
      .then(() => vm.$nextTick())
      .then(() => {
        expect(vm.$el.querySelector('.js-import-all .js-loading-button-icon')).not.toBeNull();
      });
  });

  it('imports provider repos if bulk import button is clicked', () => {
    mountComponent();

    vm.$store.dispatch('receiveReposSuccess', {
      importedProjects: [],
      providerRepos: [providerRepo],
      namespaces: [{ path: 'path' }],
    });

    return vm
      .$nextTick()
      .then(() => {
        expect(vm.$el.querySelector('.js-imported-project')).toBeNull();
        expect(vm.$el.querySelector('.js-provider-repo')).not.toBeNull();

        vm.$store.dispatch('receiveImportSuccess', { importedProject, repoId: providerRepo.id });
      })
      .then(() => vm.$nextTick())
      .then(() => {
        expect(vm.$el.querySelector('.js-imported-project')).not.toBeNull();
        expect(vm.$el.querySelector('.js-provider-repo')).toBeNull();
      });
  });

  it('polls to update the status of imported projects', () => {
    const updatedProjects = [
      {
        id: importedProject.id,
        importStatus: 'finished',
      },
    ];

    vm.$store.dispatch('receiveReposSuccess', {
      importedProjects: [importedProject],
      providerRepos: [],
      namespaces: [{ path: 'path' }],
    });

    return vm
      .$nextTick()
      .then(() => {
        const statusObject = STATUS_MAP[importedProject.importStatus];

        expect(vm.$el.querySelector('.js-imported-project')).not.toBeNull();
        expect(vm.$el.querySelector(`.${statusObject.textClass}`).textContent).toMatch(
          statusObject.text,
        );

        expect(vm.$el.querySelector(`.ic-status_${statusObject.icon}`)).not.toBeNull();

        vm.$store.dispatch('receiveJobsSuccess', updatedProjects);
      })
      .then(() => vm.$nextTick())
      .then(() => {
        const statusObject = STATUS_MAP[updatedProjects[0].importStatus];

        expect(vm.$el.querySelector('.js-imported-project')).not.toBeNull();
        expect(vm.$el.querySelector(`.${statusObject.textClass}`).textContent).toMatch(
          statusObject.text,
        );

        expect(vm.$el.querySelector(`.ic-status_${statusObject.icon}`)).not.toBeNull();
      });
  });

  it('renders filtering input field', () => {
    expect(
      vm.$el.querySelector('input[data-qa-selector="githubish_import_filter_field"]'),
    ).not.toBeNull();
  });
});

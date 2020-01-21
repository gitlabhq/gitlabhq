import Vuex from 'vuex';
import { createLocalVue, mount } from '@vue/test-utils';
import { state, actions, getters, mutations } from '~/import_projects/store';
import providerRepoTableRow from '~/import_projects/components/provider_repo_table_row.vue';
import STATUS_MAP, { STATUSES } from '~/import_projects/constants';

describe('ProviderRepoTableRow', () => {
  let vm;
  const fetchImport = jest.fn((context, data) => actions.requestImport(context, data));
  const importPath = '/import-path';
  const defaultTargetNamespace = 'user';
  const ciCdOnly = true;
  const repo = {
    id: 10,
    sanitizedName: 'sanitizedName',
    fullName: 'fullName',
    providerLink: 'providerLink',
  };

  function initStore() {
    const stubbedActions = Object.assign({}, actions, {
      fetchImport,
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
    store.dispatch('setInitialData', { importPath, defaultTargetNamespace, ciCdOnly });

    const component = mount(providerRepoTableRow, {
      localVue,
      store,
      propsData: {
        repo,
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

  it('renders a provider repo table row', () => {
    const providerLink = vm.$el.querySelector('.js-provider-link');
    const statusObject = STATUS_MAP[STATUSES.NONE];

    expect(vm.$el.classList.contains('js-provider-repo')).toBe(true);
    expect(providerLink.href).toMatch(repo.providerLink);
    expect(providerLink.textContent).toMatch(repo.fullName);
    expect(vm.$el.querySelector(`.${statusObject.textClass}`).textContent).toMatch(
      statusObject.text,
    );

    expect(vm.$el.querySelector(`.ic-status_${statusObject.icon}`)).not.toBeNull();
    expect(vm.$el.querySelector('.js-import-button')).not.toBeNull();
  });

  it('renders a select2 namespace select', () => {
    const dropdownTrigger = vm.$el.querySelector('.js-namespace-select');

    expect(dropdownTrigger).not.toBeNull();
    expect(dropdownTrigger.classList.contains('select2-container')).toBe(true);

    dropdownTrigger.click();

    expect(vm.$el.querySelector('.select2-drop')).not.toBeNull();
  });

  it('imports repo when clicking import button', () => {
    vm.$el.querySelector('.js-import-button').click();

    return vm.$nextTick().then(() => {
      const { calls } = fetchImport.mock;

      // Not using .toBeCalledWith because it expects
      // an unmatchable and undefined 3rd argument.
      expect(calls.length).toBe(1);
      expect(calls[0][1]).toEqual({
        repo,
        newName: repo.sanitizedName,
        targetNamespace: defaultTargetNamespace,
      });
    });
  });
});

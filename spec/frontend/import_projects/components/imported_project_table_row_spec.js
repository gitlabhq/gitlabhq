import Vuex from 'vuex';
import { createLocalVue, mount } from '@vue/test-utils';
import createStore from '~/import_projects/store';
import importedProjectTableRow from '~/import_projects/components/imported_project_table_row.vue';
import STATUS_MAP from '~/import_projects/constants';

describe('ImportedProjectTableRow', () => {
  let vm;
  const project = {
    id: 1,
    fullPath: 'fullPath',
    importStatus: 'finished',
    providerLink: 'providerLink',
    importSource: 'importSource',
  };

  function mountComponent() {
    const localVue = createLocalVue();
    localVue.use(Vuex);

    const component = mount(importedProjectTableRow, {
      localVue,
      store: createStore(),
      propsData: {
        project: {
          ...project,
        },
      },
      sync: false,
    });

    return component.vm;
  }

  beforeEach(() => {
    vm = mountComponent();
  });

  afterEach(() => {
    vm.$destroy();
  });

  it('renders an imported project table row', () => {
    const providerLink = vm.$el.querySelector('.js-provider-link');
    const statusObject = STATUS_MAP[project.importStatus];

    expect(vm.$el.classList.contains('js-imported-project')).toBe(true);
    expect(providerLink.href).toMatch(project.providerLink);
    expect(providerLink.textContent).toMatch(project.importSource);
    expect(vm.$el.querySelector('.js-full-path').textContent).toMatch(project.fullPath);
    expect(vm.$el.querySelector(`.${statusObject.textClass}`).textContent).toMatch(
      statusObject.text,
    );

    expect(vm.$el.querySelector(`.ic-status_${statusObject.icon}`)).not.toBeNull();
    expect(vm.$el.querySelector('.js-go-to-project').href).toMatch(project.fullPath);
  });
});

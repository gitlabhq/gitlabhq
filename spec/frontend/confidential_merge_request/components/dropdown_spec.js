import { mount } from '@vue/test-utils';
import { GlDeprecatedDropdownItem } from '@gitlab/ui';
import Dropdown from '~/confidential_merge_request/components/dropdown.vue';

let vm;

function factory(projects = []) {
  vm = mount(Dropdown, {
    propsData: {
      projects,
      selectedProject: projects[0],
    },
  });
}

describe('Confidential merge request project dropdown component', () => {
  afterEach(() => {
    vm.destroy();
  });

  it('renders dropdown items', () => {
    factory([
      {
        id: 1,
        name: 'test',
      },
      {
        id: 2,
        name: 'test',
      },
    ]);

    expect(vm.findAll(GlDeprecatedDropdownItem).length).toBe(2);
  });

  it('renders selected project icon', () => {
    factory([
      {
        id: 1,
        name: 'test',
      },
      {
        id: 2,
        name: 'test 2',
      },
    ]);

    expect(vm.find('.js-active-project-check').classes()).not.toContain('icon');
    expect(
      vm
        .findAll('.js-active-project-check')
        .at(1)
        .classes(),
    ).toContain('icon');
  });
});

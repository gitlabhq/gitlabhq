import { GlDropdown, GlDropdownItem } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
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

    expect(vm.findAll(GlDropdownItem).length).toBe(2);
  });

  it('shows lock icon', () => {
    factory();

    expect(vm.find(GlDropdown).props('icon')).toBe('lock');
  });

  it('has dropdown text', () => {
    factory();

    expect(vm.find(GlDropdown).props('text')).toBe('Select private project');
  });
});

import { shallowMount } from '@vue/test-utils';
import MockAdapter from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';
import ProjectFormGroup from '~/confidential_merge_request/components/project_form_group.vue';

const mockData = [
  {
    id: 1,
    name_with_namespace: 'root / gitlab-ce',
    path_with_namespace: 'root/gitlab-ce',
    namespace: {
      full_path: 'root',
    },
  },
  {
    id: 2,
    name_with_namespace: 'test / gitlab-ce',
    path_with_namespace: 'test/gitlab-ce',
    namespace: {
      full_path: 'test',
    },
  },
];
let vm;
let mock;

function factory(projects = mockData) {
  mock = new MockAdapter(axios);
  mock.onGet(/api\/(.*)\/projects\/gitlab-org%2Fgitlab-ce\/forks/).reply(200, projects);

  vm = shallowMount(ProjectFormGroup, {
    propsData: {
      namespacePath: 'gitlab-org',
      projectPath: 'gitlab-org/gitlab-ce',
      newForkPath: 'https://test.com',
      helpPagePath: '/help',
    },
  });
}

describe('Confidential merge request project form group component', () => {
  afterEach(() => {
    mock.restore();
    vm.destroy();
  });

  it('renders fork dropdown', () => {
    factory();

    return vm.vm.$nextTick(() => {
      expect(vm.element).toMatchSnapshot();
    });
  });

  it('sets selected project as first fork', () => {
    factory();

    return vm.vm.$nextTick(() => {
      expect(vm.vm.selectedProject).toEqual({
        id: 1,
        name: 'root / gitlab-ce',
        pathWithNamespace: 'root/gitlab-ce',
        namespaceFullpath: 'root',
      });
    });
  });

  it('renders empty state when response is empty', () => {
    factory([]);

    return vm.vm.$nextTick(() => {
      expect(vm.element).toMatchSnapshot();
    });
  });
});

import { GlSprintf } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import MockAdapter from 'axios-mock-adapter';
import ProjectFormGroup from '~/confidential_merge_request/components/project_form_group.vue';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_OK } from '~/lib/utils/http_status';

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
let wrapper;
let mock;

function factory(projects = mockData) {
  mock = new MockAdapter(axios);
  mock.onGet(/api\/(.*)\/projects\/gitlab-org%2Fgitlab-ce\/forks/).reply(HTTP_STATUS_OK, projects);

  wrapper = shallowMount(ProjectFormGroup, {
    propsData: {
      namespacePath: 'gitlab-org',
      projectPath: 'gitlab-org/gitlab-ce',
      newForkPath: 'https://test.com',
      helpPagePath: '/help',
    },
    stubs: { GlSprintf },
  });

  return axios.waitForAll();
}

describe('Confidential merge request project form group component', () => {
  afterEach(() => {
    mock.restore();
  });

  it('renders fork dropdown', async () => {
    await factory();

    expect(wrapper.element).toMatchSnapshot();
  });

  it('sets selected project as first fork', async () => {
    await factory();

    expect(wrapper.vm.selectedProject).toEqual({
      id: 1,
      name: 'root / gitlab-ce',
      pathWithNamespace: 'root/gitlab-ce',
      namespaceFullpath: 'root',
    });
  });

  it('renders empty state when response is empty', async () => {
    await factory([]);

    expect(wrapper.element).toMatchSnapshot();
  });
});

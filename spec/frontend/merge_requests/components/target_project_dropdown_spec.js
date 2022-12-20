import { mount } from '@vue/test-utils';
import { GlCollapsibleListbox } from '@gitlab/ui';
import MockAdapter from 'axios-mock-adapter';
import waitForPromises from 'helpers/wait_for_promises';
import axios from '~/lib/utils/axios_utils';
import TargetProjectDropdown from '~/merge_requests/components/target_project_dropdown.vue';

let wrapper;
let mock;

function factory() {
  wrapper = mount(TargetProjectDropdown, {
    provide: {
      targetProjectsPath: '/gitlab-org/gitlab/target_projects',
      currentProject: { value: 1, text: 'gitlab-org/gitlab' },
    },
  });
}

const findDropdown = () => wrapper.findComponent(GlCollapsibleListbox);

describe('Merge requests target project dropdown component', () => {
  beforeEach(() => {
    mock = new MockAdapter(axios);
    mock.onGet('/gitlab-org/gitlab/target_projects').reply(200, [
      {
        id: 10,
        name: 'Gitlab Test',
        full_path: '/root/gitlab-test',
        full_name: 'Administrator / Gitlab Test',
        refs_url: '/root/gitlab-test/refs',
      },
      {
        id: 1,
        name: 'Gitlab Test',
        full_path: '/gitlab-org/gitlab-test',
        full_name: 'Gitlab Org / Gitlab Test',
        refs_url: '/gitlab-org/gitlab-test/refs',
      },
    ]);
  });

  afterEach(() => {
    wrapper.destroy();
    mock.restore();
  });

  it('creates hidden input with currentProject ID', () => {
    factory();

    expect(wrapper.find('[data-testid="target-project-input"]').attributes('value')).toBe('1');
  });

  it('renders list of projects', async () => {
    factory();

    wrapper.find('[data-testid="base-dropdown-toggle"]').trigger('click');

    await waitForPromises();

    expect(wrapper.findAll('li').length).toBe(2);
    expect(wrapper.findAll('li').at(0).text()).toBe('root/gitlab-test');
    expect(wrapper.findAll('li').at(1).text()).toBe('gitlab-org/gitlab-test');
  });

  it('searches projects', async () => {
    factory();

    wrapper.find('[data-testid="base-dropdown-toggle"]').trigger('click');

    await waitForPromises();

    findDropdown().vm.$emit('search', 'test');

    jest.advanceTimersByTime(500);
    await waitForPromises();

    expect(mock.history.get[1].params).toEqual({ search: 'test' });
  });
});

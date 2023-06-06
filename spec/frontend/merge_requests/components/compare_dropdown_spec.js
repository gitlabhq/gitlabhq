import { mount } from '@vue/test-utils';
import { GlCollapsibleListbox } from '@gitlab/ui';
import MockAdapter from 'axios-mock-adapter';
import waitForPromises from 'helpers/wait_for_promises';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_OK } from '~/lib/utils/http_status';
import CompareDropdown from '~/merge_requests/components/compare_dropdown.vue';

let wrapper;
let mock;

function factory(propsData = {}) {
  wrapper = mount(CompareDropdown, {
    propsData: {
      endpoint: '/gitlab-org/gitlab/target_projects',
      default: { value: 1, text: 'gitlab-org/gitlab' },
      dropdownHeader: 'Select',
      inputId: 'input_id',
      inputName: 'input_name',
      isProject: true,
      ...propsData,
    },
  });
}

const findDropdown = () => wrapper.findComponent(GlCollapsibleListbox);

describe('Merge requests compare dropdown component', () => {
  beforeEach(() => {
    mock = new MockAdapter(axios);
    mock.onGet('/gitlab-org/gitlab/target_projects').reply(HTTP_STATUS_OK, [
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
    const items = wrapper.findAll('[role="option"]');
    expect(items.length).toBe(2);
    expect(items.at(0).text()).toBe('root/gitlab-test');
    expect(items.at(1).text()).toBe('gitlab-org/gitlab-test');
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

  it('renders static data', async () => {
    factory({
      endpoint: undefined,
      staticData: [
        {
          value: '10',
          text: 'GitLab Org',
        },
      ],
    });

    wrapper.find('[data-testid="base-dropdown-toggle"]').trigger('click');

    await waitForPromises();

    expect(wrapper.findAll('[role="option"]').length).toBe(1);
  });
});

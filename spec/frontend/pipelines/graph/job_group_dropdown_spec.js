import { shallowMount, mount } from '@vue/test-utils';
import JobGroupDropdown from '~/pipelines/components/graph/job_group_dropdown.vue';

describe('job group dropdown component', () => {
  const group = {
    jobs: [
      {
        id: 4256,
        name: '<img src=x onerror=alert(document.domain)>',
        status: {
          icon: 'status_success',
          text: 'passed',
          label: 'passed',
          tooltip: 'passed',
          group: 'success',
          details_path: '/root/ci-mock/builds/4256',
          has_details: true,
          action: {
            icon: 'retry',
            title: 'Retry',
            path: '/root/ci-mock/builds/4256/retry',
            method: 'post',
          },
        },
      },
      {
        id: 4299,
        name: 'test',
        status: {
          icon: 'status_success',
          text: 'passed',
          label: 'passed',
          tooltip: 'passed',
          group: 'success',
          details_path: '/root/ci-mock/builds/4299',
          has_details: true,
          action: {
            icon: 'retry',
            title: 'Retry',
            path: '/root/ci-mock/builds/4299/retry',
            method: 'post',
          },
        },
      },
    ],
    name: 'rspec:linux',
    size: 2,
    status: {
      icon: 'status_success',
      text: 'passed',
      label: 'passed',
      tooltip: 'passed',
      group: 'success',
      details_path: '/root/ci-mock/builds/4256',
      has_details: true,
      action: {
        icon: 'retry',
        title: 'Retry',
        path: '/root/ci-mock/builds/4256/retry',
        method: 'post',
      },
    },
  };

  let wrapper;
  const findButton = () => wrapper.find('button');

  const createComponent = ({ mountFn = shallowMount }) => {
    wrapper = mountFn(JobGroupDropdown, { propsData: { group } });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  beforeEach(() => {
    createComponent({ mountFn: mount });
  });

  it('renders button with group name and size', () => {
    expect(findButton().text()).toContain(group.name);
    expect(findButton().text()).toContain(group.size);
  });

  it('renders dropdown with jobs', () => {
    expect(wrapper.findAll('.scrollable-menu>ul>li').length).toBe(group.jobs.length);
  });
});

import { shallowMount, mount } from '@vue/test-utils';
import { GlDisclosureDropdown, GlDisclosureDropdownItem } from '@gitlab/ui';

import JobGroupDropdown from '~/ci/pipeline_details/graph/components/job_group_dropdown.vue';
import JobItem from '~/ci/pipeline_details/graph/components/job_item.vue';
import { SINGLE_JOB } from '~/ci/pipeline_details/graph/constants';

describe('job group dropdown component', () => {
  const group = {
    name: 'rspec:linux',
    size: 2,
    status: {
      icon: 'status_success',
      text: 'passed',
      label: 'passed',
      tooltip: 'passed',
      group: 'success',
      detailsPath: '/root/ci-mock/builds/4256',
      hasDetails: true,
      action: {
        icon: 'retry',
        title: 'Retry',
        path: '/root/ci-mock/builds/4256/retry',
        method: 'post',
      },
    },
    jobs: [
      {
        id: 4256,
        name: 'rspec:linux 1/2',
        status: {
          icon: 'status_success',
          text: 'passed',
          label: 'passed',
          tooltip: 'passed',
          group: 'success',
          detailsPath: '/root/ci-mock/builds/4256',
          hasDetails: true,
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
        name: 'rspec:linux 2/2',
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
  };

  let wrapper;
  const findJobItem = () => wrapper.findComponent(JobItem);
  const findTriggerButton = () => wrapper.find('button');
  const findDisclosureDropdown = () => wrapper.findComponent(GlDisclosureDropdown);
  const findDisclosureDropdownItems = () => wrapper.findAllComponents(GlDisclosureDropdownItem);

  const createComponent = ({ props, mountFn = shallowMount } = {}) => {
    wrapper = mountFn(JobGroupDropdown, {
      propsData: {
        group,
        ...props,
      },
    });
  };

  it('renders dropdown with jobs', () => {
    createComponent({ mountFn: mount });

    expect(wrapper.findAll('[data-testid="disclosure-content"] > li').length).toBe(
      group.jobs.length,
    );
  });

  it('renders dropdown', () => {
    createComponent();

    expect(findDisclosureDropdown().props()).toMatchObject({
      block: true,
      placement: 'right-start',
    });
  });

  it('renders trigger button with group name and size', () => {
    createComponent({ mountFn: mount });

    expect(findJobItem().text().trim()).toBe(group.name);
    expect(findJobItem().props()).toMatchObject({
      type: 'job_dropdown',
      groupTooltip: 'rspec:linux - passed',
      job: group,
    });
    expect(findTriggerButton().text()).toContain(group.size.toString());
  });

  it('renders stage name when provided', () => {
    createComponent({
      props: {
        stageName: 'my-stage-name',
      },
      mountFn: mount,
    });

    expect(findJobItem().props()).toMatchObject({
      stageName: 'my-stage-name',
    });
  });

  it('renders parallel jobs in group', () => {
    createComponent({ mountFn: mount });

    const [item1, item2] = findDisclosureDropdownItems().wrappers;

    expect(findDisclosureDropdownItems()).toHaveLength(2);

    expect(item1.props('item')).toEqual({
      text: group.jobs[0].name,
      href: group.jobs[0].status.detailsPath,
    });
    expect(item1.findComponent(JobItem).props()).toMatchObject({
      isLink: false,
      job: group.jobs[0],
      type: SINGLE_JOB,
      cssClassJobName: 'gl-p-3',
    });

    expect(item2.props('item')).toEqual({
      text: group.jobs[1].name,
      href: group.jobs[1].status.detailsPath,
    });
    expect(item2.findComponent(JobItem).props()).toMatchObject({
      isLink: false,
      job: group.jobs[1],
      type: SINGLE_JOB,
      cssClassJobName: 'gl-p-3',
    });
  });
});

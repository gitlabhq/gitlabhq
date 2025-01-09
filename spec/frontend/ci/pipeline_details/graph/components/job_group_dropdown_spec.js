import { shallowMount, mount } from '@vue/test-utils';
import { GlDisclosureDropdown } from '@gitlab/ui';

import JobDropdownItem from '~/ci/common/private/job_dropdown_item.vue';
import JobGroupDropdown from '~/ci/pipeline_details/graph/components/job_group_dropdown.vue';
import JobItem from '~/ci/pipeline_details/graph/components/job_item.vue';

describe('job group dropdown component', () => {
  const group = {
    name: 'rspec:linux',
    size: 2,
    status: {
      icon: 'status_success',
      text: 'passed',
      label: 'passed',
      tooltip: 'Passed',
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
  const findJobDropdownItems = () => wrapper.findAllComponents(JobDropdownItem);

  const createComponent = ({ props, mountFn = shallowMount } = {}) => {
    wrapper = mountFn(JobGroupDropdown, {
      propsData: {
        group,
        ...props,
      },
    });
  };

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

    const [item1, item2] = findJobDropdownItems().wrappers;

    expect(findJobDropdownItems()).toHaveLength(2);

    expect(item1.props('job')).toEqual(group.jobs[0]);
    expect(item2.props('job')).toEqual(group.jobs[1]);
  });

  describe('tooltip', () => {
    it('renders the text as basic status', () => {
      createComponent({ mountFn: mount });

      expect(findDisclosureDropdown().attributes('title')).toBe(group.status.tooltip);
    });

    it('renders the detailed status tooltip if available', () => {
      const groupWithExtendedTooltip = {
        ...group,
        status: {
          ...group.status,
          tooltip: 'Failed - (stuck or timeout failure) (allowed to fail)',
          text: 'Failed text',
        },
      };

      createComponent({
        props: {
          group: groupWithExtendedTooltip,
        },
        mountFn: mount,
      });

      expect(findDisclosureDropdown().attributes('title')).toBe(
        groupWithExtendedTooltip.status.tooltip,
      );
    });

    it('renders the status text as fallback if tooltip is not available', () => {
      const groupWithJustTextTooltip = {
        ...group,
        status: {
          ...group.status,
          tooltip: '',
          text: 'Passed text',
        },
      };

      createComponent({
        props: {
          group: groupWithJustTextTooltip,
        },
        mountFn: mount,
      });

      expect(findDisclosureDropdown().attributes('title')).toBe(
        groupWithJustTextTooltip.status.text,
      );
    });
  });
});

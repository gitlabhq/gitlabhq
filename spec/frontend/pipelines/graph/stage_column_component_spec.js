import { shallowMount } from '@vue/test-utils';

import stageColumnComponent from '~/pipelines/components/graph/stage_column_component.vue';

describe('stage column component', () => {
  const mockJob = {
    id: 4250,
    name: 'test',
    status: {
      icon: 'status_success',
      text: 'passed',
      label: 'passed',
      group: 'success',
      details_path: '/root/ci-mock/builds/4250',
      action: {
        icon: 'retry',
        title: 'Retry',
        path: '/root/ci-mock/builds/4250/retry',
        method: 'post',
      },
    },
  };

  let wrapper;

  beforeEach(() => {
    const mockGroups = [];
    for (let i = 0; i < 3; i += 1) {
      const mockedJob = { ...mockJob };
      mockedJob.id += i;
      mockGroups.push(mockedJob);
    }

    wrapper = shallowMount(stageColumnComponent, {
      propsData: {
        title: 'foo',
        groups: mockGroups,
        hasTriggeredBy: false,
      },
    });
  });

  it('should render provided title', () => {
    expect(
      wrapper
        .find('.stage-name')
        .text()
        .trim(),
    ).toBe('foo');
  });

  it('should render the provided groups', () => {
    expect(wrapper.findAll('.builds-container > ul > li').length).toBe(
      wrapper.props('groups').length,
    );
  });

  describe('jobId', () => {
    it('escapes job name', () => {
      wrapper = shallowMount(stageColumnComponent, {
        propsData: {
          groups: [
            {
              id: 4259,
              name: '<img src=x onerror=alert(document.domain)>',
              status: {
                icon: 'status_success',
                label: 'success',
                tooltip: '<img src=x onerror=alert(document.domain)>',
              },
            },
          ],
          title: 'test',
          hasTriggeredBy: false,
        },
      });

      expect(wrapper.find('.builds-container li').attributes('id')).toBe(
        'ci-badge-&lt;img src=x onerror=alert(document.domain)&gt;',
      );
    });
  });

  describe('with action', () => {
    it('renders action button', () => {
      wrapper = shallowMount(stageColumnComponent, {
        propsData: {
          groups: [
            {
              id: 4259,
              name: '<img src=x onerror=alert(document.domain)>',
              status: {
                icon: 'status_success',
                label: 'success',
                tooltip: '<img src=x onerror=alert(document.domain)>',
              },
            },
          ],
          title: 'test',
          hasTriggeredBy: false,
          action: {
            icon: 'play',
            title: 'Play all',
            path: 'action',
          },
        },
      });

      expect(wrapper.find('.js-stage-action').exists()).toBe(true);
    });
  });

  describe('without action', () => {
    it('does not render action button', () => {
      wrapper = shallowMount(stageColumnComponent, {
        propsData: {
          groups: [
            {
              id: 4259,
              name: '<img src=x onerror=alert(document.domain)>',
              status: {
                icon: 'status_success',
                label: 'success',
                tooltip: '<img src=x onerror=alert(document.domain)>',
              },
            },
          ],
          title: 'test',
          hasTriggeredBy: false,
        },
      });

      expect(wrapper.find('.js-stage-action').exists()).toBe(false);
    });
  });
});

import { GlSprintf } from '@gitlab/ui';
import { mount, shallowMount } from '@vue/test-utils';
import { GROUP_TYPE, STATUS_ONLINE } from '~/runner/constants';
import { TYPE_CI_RUNNER } from '~/graphql_shared/constants';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import TimeAgo from '~/vue_shared/components/time_ago_tooltip.vue';

import RunnerHeader from '~/runner/components/runner_header.vue';
import RunnerTypeBadge from '~/runner/components/runner_type_badge.vue';
import RunnerStatusBadge from '~/runner/components/runner_status_badge.vue';

import { runnerData } from '../mock_data';

const mockRunner = runnerData.data.runner;

describe('RunnerHeader', () => {
  let wrapper;

  const findRunnerTypeBadge = () => wrapper.findComponent(RunnerTypeBadge);
  const findRunnerStatusBadge = () => wrapper.findComponent(RunnerStatusBadge);
  const findTimeAgo = () => wrapper.findComponent(TimeAgo);

  const createComponent = ({ runner = {}, mountFn = shallowMount } = {}) => {
    wrapper = mountFn(RunnerHeader, {
      propsData: {
        runner: {
          ...mockRunner,
          ...runner,
        },
      },
      stubs: {
        GlSprintf,
        TimeAgo,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  it('displays the runner status', () => {
    createComponent({
      mountFn: mount,
      runner: {
        status: STATUS_ONLINE,
      },
    });

    expect(findRunnerStatusBadge().text()).toContain(`online`);
  });

  it('displays the runner type', () => {
    createComponent({
      mountFn: mount,
      runner: {
        runnerType: GROUP_TYPE,
      },
    });

    expect(findRunnerTypeBadge().text()).toContain(`group`);
  });

  it('displays the runner id', () => {
    createComponent({
      runner: {
        id: convertToGraphQLId(TYPE_CI_RUNNER, 99),
      },
    });

    expect(wrapper.text()).toContain(`Runner #99`);
  });

  it('displays the runner creation time', () => {
    createComponent();

    expect(wrapper.text()).toMatch(/created .+/);
    expect(findTimeAgo().props('time')).toBe(mockRunner.createdAt);
  });

  it('does not display runner creation time if createdAt missing', () => {
    createComponent({
      runner: {
        id: convertToGraphQLId(TYPE_CI_RUNNER, 99),
        createdAt: null,
      },
    });

    expect(wrapper.text()).toContain(`Runner #99`);
    expect(wrapper.text()).not.toMatch(/created .+/);
    expect(findTimeAgo().exists()).toBe(false);
  });
});

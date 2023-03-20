import { GlSprintf } from '@gitlab/ui';
import { mountExtended, shallowMountExtended } from 'helpers/vue_test_utils_helper';
import {
  I18N_STATUS_ONLINE,
  I18N_GROUP_TYPE,
  GROUP_TYPE,
  STATUS_ONLINE,
} from '~/ci/runner/constants';
import { TYPENAME_CI_RUNNER } from '~/graphql_shared/constants';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import TimeAgo from '~/vue_shared/components/time_ago_tooltip.vue';

import RunnerHeader from '~/ci/runner/components/runner_header.vue';
import RunnerTypeBadge from '~/ci/runner/components/runner_type_badge.vue';
import RunnerStatusBadge from '~/ci/runner/components/runner_status_badge.vue';

import { runnerData } from '../mock_data';

const mockRunner = runnerData.data.runner;

describe('RunnerHeader', () => {
  let wrapper;

  const findRunnerTypeBadge = () => wrapper.findComponent(RunnerTypeBadge);
  const findRunnerStatusBadge = () => wrapper.findComponent(RunnerStatusBadge);
  const findRunnerLockedIcon = () => wrapper.findByTestId('lock-icon');
  const findTimeAgo = () => wrapper.findComponent(TimeAgo);

  const createComponent = ({ runner = {}, options = {}, mountFn = shallowMountExtended } = {}) => {
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
      ...options,
    });
  };

  it('displays the runner status', () => {
    createComponent({
      mountFn: mountExtended,
      runner: {
        status: STATUS_ONLINE,
      },
    });

    expect(findRunnerStatusBadge().text()).toContain(I18N_STATUS_ONLINE);
  });

  it('displays the runner type', () => {
    createComponent({
      mountFn: mountExtended,
      runner: {
        runnerType: GROUP_TYPE,
      },
    });

    expect(findRunnerTypeBadge().text()).toContain(I18N_GROUP_TYPE);
  });

  it('displays the runner id', () => {
    createComponent({
      runner: {
        id: convertToGraphQLId(TYPENAME_CI_RUNNER, 99),
      },
    });

    expect(wrapper.text()).toContain('Runner #99');
  });

  it('displays the runner locked icon', () => {
    createComponent({
      runner: {
        locked: true,
      },
      mountFn: mountExtended,
    });

    expect(findRunnerLockedIcon().exists()).toBe(true);
  });

  it('displays the runner creation time', () => {
    createComponent();

    expect(wrapper.text()).toMatch(/created .+/);
    expect(findTimeAgo().props('time')).toBe(mockRunner.createdAt);
  });

  it('does not display runner creation time if "createdAt" is missing', () => {
    createComponent({
      runner: {
        id: convertToGraphQLId(TYPENAME_CI_RUNNER, 99),
        createdAt: null,
      },
    });

    expect(wrapper.text()).toContain('Runner #99');
    expect(wrapper.text()).not.toMatch(/created .+/);
    expect(findTimeAgo().exists()).toBe(false);
  });

  it('displays actions in a slot', () => {
    createComponent({
      options: {
        slots: {
          actions: '<div data-testid="actions-content">My Actions</div>',
        },
        mountFn: mountExtended,
      },
    });

    expect(wrapper.findByTestId('actions-content').text()).toBe('My Actions');
  });
});

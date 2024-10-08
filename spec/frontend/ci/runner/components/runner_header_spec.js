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

import PageHeading from '~/vue_shared/components/page_heading.vue';
import RunnerHeader from '~/ci/runner/components/runner_header.vue';
import RunnerCreatedAt from '~/ci/runner/components/runner_created_at.vue';
import RunnerTypeBadge from '~/ci/runner/components/runner_type_badge.vue';
import RunnerStatusBadge from '~/ci/runner/components/runner_status_badge.vue';

import { runnerData } from '../mock_data';

const mockRunner = runnerData.data.runner;
const mockRunnerSha = mockRunner.shortSha;

describe('RunnerHeader', () => {
  let wrapper;

  const findPageHeading = () => wrapper.findComponent(PageHeading);
  const findRunnerTypeBadge = () => wrapper.findComponent(RunnerTypeBadge);
  const findRunnerStatusBadge = () => wrapper.findComponent(RunnerStatusBadge);
  const findRunnerLockedIcon = () => wrapper.findByTestId('lock-icon');

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
        PageHeading,
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

    expect(findPageHeading().props('heading')).toBe(`#99 (${mockRunnerSha})`);
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

  it('displays the runner creation data', () => {
    createComponent();

    expect(wrapper.findComponent(RunnerCreatedAt).props('runner')).toEqual(mockRunner);
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

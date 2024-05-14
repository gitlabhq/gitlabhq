import { GlLink } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import ExperimentBadge from '~/vue_shared/components/badges/experiment_badge.vue';

import LogViewerTopBar from '~/ci/job_log_viewer/components/log_viewer_top_bar.vue';

describe('LogViewerTopBar', () => {
  let wrapper;

  const createWrapper = ({ props = {}, mountFn = shallowMountExtended } = {}) => {
    wrapper = mountFn(LogViewerTopBar, {
      propsData: {
        ...props,
      },
    });
  };

  const findExperimentBadge = () => wrapper.findComponent(ExperimentBadge);
  const findLink = () => wrapper.findComponent(GlLink);

  it('renders help experiment badge with link', () => {
    createWrapper();

    expect(findExperimentBadge().exists()).toBe(true);

    expect(findLink().attributes('href')).toEqual(
      'https://gitlab.com/gitlab-org/gitlab/-/issues/454817',
    );
  });
});

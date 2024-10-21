import { GlExperimentBadge } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';

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

  const findExperimentBadge = () => wrapper.findComponent(GlExperimentBadge);

  it('renders help experiment badge', () => {
    createWrapper();

    expect(findExperimentBadge().exists()).toBe(true);
  });
});

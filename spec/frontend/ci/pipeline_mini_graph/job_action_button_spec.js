import { GlButton, GlIcon } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';

import JobActionButton from '~/ci/pipeline_mini_graph/job_action_button.vue';
import { mockJobActions } from './mock_data';

describe('JobActionButton', () => {
  let wrapper;

  const jobAction = mockJobActions[0];

  const defaultProps = {
    jobAction,
    jobId: 'gid://gitlab/Ci::Build/5521',
    jobName: 'test_job',
  };

  const createComponent = ({ props = {} } = {}) => {
    wrapper = shallowMountExtended(JobActionButton, {
      propsData: {
        ...defaultProps,
        ...props,
      },
    });

    return waitForPromises();
  };

  const findActionButton = () => wrapper.findComponent(GlButton);
  const findActionIcon = () => wrapper.findComponent(GlIcon);

  describe('when mounted', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders the action icon', () => {
      expect(findActionIcon().exists()).toBe(true);
    });

    it('renders the tooltip', () => {
      expect(findActionButton().exists()).toBe(true);
    });

    describe('job action button', () => {
      describe.each`
        action          | icon          | tooltip         | mockIndex
        ${'cancel'}     | ${'cancel'}   | ${'Cancel'}     | ${0}
        ${'run'}        | ${'play'}     | ${'Run'}        | ${1}
        ${'retry'}      | ${'retry'}    | ${'Run again'}  | ${2}
        ${'unschedule'} | ${'time-out'} | ${'Unschedule'} | ${3}
      `('$action action', ({ icon, mockIndex, tooltip }) => {
        beforeEach(() => {
          createComponent({ props: { jobAction: mockJobActions[mockIndex] } });
        });

        it('displays the correct icon', () => {
          expect(findActionIcon().exists()).toBe(true);
          expect(findActionIcon().props('name')).toBe(icon);
        });

        it('displays the correct tooltip', () => {
          expect(findActionButton().exists()).toBe(true);
          expect(findActionButton().attributes('title')).toBe(tooltip);
        });
      });
    });
  });
});

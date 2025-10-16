import { GlLink, GlSprintf, GlPopover } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import ValidatePopover from '~/ci/pipeline_editor/components/popovers/validate_pipeline_popover.vue';
import { VALIDATE_TAB_FEEDBACK_URL } from '~/ci/pipeline_editor/constants';
import { mockSimulatePipelineHelpPagePath } from '../../mock_data';

describe('ValidatePopover component', () => {
  let wrapper;
  const containerId = 'my-container-id';

  const createComponent = ({ stubs } = {}) => {
    wrapper = shallowMountExtended(ValidatePopover, {
      provide: {
        simulatePipelineHelpPagePath: mockSimulatePipelineHelpPagePath,
      },
      propsData: {
        containerId,
      },
      stubs,
    });
  };

  const findPopover = () => wrapper.findComponent(GlPopover);
  const findHelpLink = () => wrapper.findByTestId('help-link');
  const findFeedbackLink = () => wrapper.findByTestId('feedback-link');

  describe('template', () => {
    beforeEach(() => {
      createComponent({
        stubs: { GlLink, GlSprintf },
      });
    });

    it('uses provided container id', () => {
      expect(findPopover().props('container')).toBe(containerId);
    });

    it('renders help link', () => {
      expect(findHelpLink().exists()).toBe(true);
      expect(findHelpLink().attributes('href')).toBe(mockSimulatePipelineHelpPagePath);
    });

    it('renders feedback link', () => {
      expect(findFeedbackLink().exists()).toBe(true);
      expect(findFeedbackLink().attributes('href')).toBe(VALIDATE_TAB_FEEDBACK_URL);
    });
  });
});

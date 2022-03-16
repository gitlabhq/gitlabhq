import { GlModal, GlFormRadio } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { getBaseURL, visitUrl } from '~/lib/utils/url_utility';
import { mockTracking } from 'helpers/tracking_helper';
import {
  CF_BASE_URL,
  TEMPLATES_BASE_URL,
  EASY_BUTTONS,
} from '~/vue_shared/components/runner_aws_deployments/constants';
import RunnerAwsDeploymentsModal from '~/vue_shared/components/runner_aws_deployments/runner_aws_deployments_modal.vue';

jest.mock('~/lib/utils/url_utility', () => ({
  ...jest.requireActual('~/lib/utils/url_utility'),
  visitUrl: jest.fn(),
}));

describe('RunnerAwsDeploymentsModal', () => {
  let wrapper;

  const findModal = () => wrapper.findComponent(GlModal);
  const findEasyButtons = () => wrapper.findAllComponents(GlFormRadio);

  const createComponent = () => {
    wrapper = shallowMount(RunnerAwsDeploymentsModal, {
      propsData: {
        modalId: 'runner-aws-deployments-modal',
      },
    });
  };

  beforeEach(() => {
    createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('renders the modal', () => {
    expect(wrapper.element).toMatchSnapshot();
  });

  it('should contain all easy buttons', () => {
    expect(findEasyButtons()).toHaveLength(EASY_BUTTONS.length);
  });

  describe('first easy button', () => {
    it('should contain the correct description', () => {
      expect(findEasyButtons().at(0).text()).toContain(EASY_BUTTONS[0].description);
    });

    it('should contain the correct link', () => {
      const templateUrl = encodeURIComponent(TEMPLATES_BASE_URL + EASY_BUTTONS[0].templateName);
      const { stackName } = EASY_BUTTONS[0];
      const instanceUrl = encodeURIComponent(getBaseURL());
      const url = `${CF_BASE_URL}templateURL=${templateUrl}&stackName=${stackName}&param_3GITLABRunnerInstanceURL=${instanceUrl}`;

      findModal().vm.$emit('primary');

      expect(visitUrl).toHaveBeenCalledWith(url, true);
    });

    it('should track an event when clicked', () => {
      const trackingSpy = mockTracking(undefined, wrapper.element, jest.spyOn);

      findModal().vm.$emit('primary');

      expect(trackingSpy).toHaveBeenCalledTimes(1);
      expect(trackingSpy).toHaveBeenCalledWith(undefined, 'template_clicked', {
        label: EASY_BUTTONS[0].stackName,
      });
    });
  });
});

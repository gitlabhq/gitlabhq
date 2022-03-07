import { GlLink } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { getBaseURL } from '~/lib/utils/url_utility';
import { mockTracking } from 'helpers/tracking_helper';
import {
  CF_BASE_URL,
  TEMPLATES_BASE_URL,
  EASY_BUTTONS,
} from '~/vue_shared/components/runner_aws_deployments/constants';
import RunnerAwsDeploymentsModal from '~/vue_shared/components/runner_aws_deployments/runner_aws_deployments_modal.vue';

describe('RunnerAwsDeploymentsModal', () => {
  let wrapper;
  let trackingSpy;

  const findEasyButtons = () => wrapper.findAllComponents(GlLink);

  const createComponent = () => {
    wrapper = shallowMount(RunnerAwsDeploymentsModal, {
      propsData: {
        modalId: 'runner-aws-deployments-modal',
        imgSrc: '/assets/aws-cloud-formation.png',
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
    const findFirstButton = () => findEasyButtons().at(0);

    it('should contain the correct description', () => {
      expect(findFirstButton().text()).toBe(EASY_BUTTONS[0].description);
    });

    it('should contain the correct link', () => {
      const link = findFirstButton().attributes('href');

      expect(link.startsWith(CF_BASE_URL)).toBe(true);
      expect(
        link.includes(
          `templateURL=${encodeURIComponent(TEMPLATES_BASE_URL + EASY_BUTTONS[0].templateName)}`,
        ),
      ).toBe(true);
      expect(link.includes(`stackName=${EASY_BUTTONS[0].stackName}`)).toBe(true);
      expect(
        link.includes(`param_3GITLABRunnerInstanceURL=${encodeURIComponent(getBaseURL())}`),
      ).toBe(true);
    });

    it('should track an event when clicked', () => {
      trackingSpy = mockTracking(undefined, wrapper.element, jest.spyOn);

      findFirstButton().vm.$emit('click');

      expect(trackingSpy).toHaveBeenCalledTimes(1);
      expect(trackingSpy).toHaveBeenCalledWith(undefined, 'template_clicked', {
        label: EASY_BUTTONS[0].stackName,
      });
    });
  });
});

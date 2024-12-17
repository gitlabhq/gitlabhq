import {
  GlAccordion,
  GlAccordionItem,
  GlButton,
  GlFormRadio,
  GlFormRadioGroup,
  GlLink,
  GlSprintf,
} from '@gitlab/ui';
import { getBaseURL, visitUrl } from '~/lib/utils/url_utility';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { mockTracking } from 'helpers/tracking_helper';
import {
  AWS_README_URL,
  AWS_CF_BASE_URL,
  AWS_TEMPLATES_BASE_URL,
  AWS_EASY_BUTTONS,
} from '~/ci/runner/components/registration/runner_instructions/constants';

import RunnerAwsInstructions from '~/ci/runner/components/registration/runner_instructions/instructions/runner_aws_instructions.vue';
import ModalCopyButton from '~/vue_shared/components/modal_copy_button.vue';

jest.mock('~/lib/utils/url_utility', () => ({
  ...jest.requireActual('~/lib/utils/url_utility'),
  visitUrl: jest.fn(),
}));

const mockRegistrationToken = 'MY_TOKEN';

describe('RunnerAwsInstructions', () => {
  let wrapper;

  const findEasyButtonsRadioGroup = () => wrapper.findComponent(GlFormRadioGroup);
  const findEasyButtons = () => wrapper.findAllComponents(GlFormRadio);
  const findEasyButtonAt = (i) => findEasyButtons().at(i);
  const findLink = () => wrapper.findComponent(GlLink);
  const findModalCopyButton = () => wrapper.findComponent(ModalCopyButton);
  const findOkButton = () =>
    wrapper
      .findAllComponents(GlButton)
      .filter((w) => w.props('variant') === 'confirm')
      .at(0);
  const findCloseButton = () => wrapper.findByTestId('close-btn');

  const createComponent = ({ props = {} } = {}) => {
    wrapper = shallowMountExtended(RunnerAwsInstructions, {
      propsData: {
        registrationToken: mockRegistrationToken,
        ...props,
      },
      stubs: {
        GlSprintf,
      },
    });
  };

  beforeEach(() => {
    createComponent();
  });

  it('should contain every button', () => {
    expect(findEasyButtons()).toHaveLength(AWS_EASY_BUTTONS.length);
  });

  const AWS_EASY_BUTTONS_PARAMS = AWS_EASY_BUTTONS.map((val, idx) => ({ ...val, idx }));

  describe.each(AWS_EASY_BUTTONS_PARAMS)(
    'easy button %#',
    ({ idx, description, moreDetails1, moreDetails2, templateName, stackName }) => {
      it('should contain button description', () => {
        const text = findEasyButtonAt(idx).text();

        expect(text).toContain(description);
        expect(text).toContain(moreDetails1);
        expect(text).toContain(moreDetails2);
      });

      it('should show more details', () => {
        const accordion = findEasyButtonAt(idx).findComponent(GlAccordion);
        const accordionItem = accordion.findComponent(GlAccordionItem);

        expect(accordion.props('headerLevel')).toBe(3);
        expect(accordionItem.props('title')).toBe('More Details');
        expect(accordionItem.props('titleVisible')).toBe('Less Details');
      });

      describe('when clicked', () => {
        let trackingSpy;

        beforeEach(() => {
          trackingSpy = mockTracking(undefined, wrapper.element, jest.spyOn);

          findEasyButtonsRadioGroup().vm.$emit('input', idx);
          findOkButton().vm.$emit('click');
        });

        it('should contain the correct link', () => {
          const templateUrl = encodeURIComponent(AWS_TEMPLATES_BASE_URL + templateName);
          const instanceUrl = encodeURIComponent(getBaseURL());
          const url = `${AWS_CF_BASE_URL}templateURL=${templateUrl}&stackName=${stackName}&param_3GITLABRunnerInstanceURL=${instanceUrl}`;

          expect(visitUrl).toHaveBeenCalledTimes(1);
          expect(visitUrl).toHaveBeenCalledWith(url, true);
        });

        it('should track an event when clicked', () => {
          expect(trackingSpy).toHaveBeenCalledTimes(1);
          expect(trackingSpy).toHaveBeenCalledWith(undefined, 'template_clicked', {
            label: stackName,
          });
        });
      });
    },
  );

  it('displays link with more information', () => {
    expect(findLink().attributes('href')).toBe(AWS_README_URL);
  });

  it('shows registration token and copy button', () => {
    const token = wrapper.findByText(mockRegistrationToken);

    expect(token.exists()).toBe(true);
    expect(token.element.tagName).toBe('PRE');

    expect(findModalCopyButton().props('text')).toBe(mockRegistrationToken);
  });

  it('does not show registration token and copy button when token is not present', () => {
    createComponent({ props: { registrationToken: null } });

    expect(wrapper.find('pre').exists()).toBe(false);
    expect(findModalCopyButton().exists()).toBe(false);
  });

  it('triggers the modal to close', () => {
    findCloseButton().vm.$emit('click');

    expect(wrapper.emitted('close')).toHaveLength(1);
  });
});

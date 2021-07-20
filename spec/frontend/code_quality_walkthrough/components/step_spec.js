import { GlButton, GlPopover } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Cookies from 'js-cookie';
import Step from '~/code_quality_walkthrough/components/step.vue';
import { EXPERIMENT_NAME, STEPS } from '~/code_quality_walkthrough/constants';
import { TRACKING_CONTEXT_SCHEMA } from '~/experimentation/constants';
import { getParameterByName } from '~/lib/utils/url_utility';
import Tracking from '~/tracking';

jest.mock('~/lib/utils/url_utility', () => ({
  ...jest.requireActual('~/lib/utils/url_utility'),
  getParameterByName: jest.fn(),
}));

let wrapper;

function factory({ step, link }) {
  wrapper = shallowMount(Step, {
    propsData: { step, link },
  });
}

afterEach(() => {
  wrapper.destroy();
});

const dummyLink = '/group/project/-/jobs/:id?code_quality_walkthrough=true';
const dummyContext = 'experiment_context';

const findButton = () => wrapper.findComponent(GlButton);
const findPopover = () => wrapper.findComponent(GlPopover);

describe('When the code_quality_walkthrough URL parameter is missing', () => {
  beforeEach(() => {
    getParameterByName.mockReturnValue(false);
  });

  it('does not render the component', () => {
    factory({
      step: STEPS.commitCiFile,
    });

    expect(findPopover().exists()).toBe(false);
  });
});

describe('When the code_quality_walkthrough URL parameter is present', () => {
  beforeEach(() => {
    getParameterByName.mockReturnValue(true);
    Cookies.set(EXPERIMENT_NAME, { data: dummyContext });
  });

  afterEach(() => {
    Cookies.remove(EXPERIMENT_NAME);
  });

  describe('When mounting the component', () => {
    beforeEach(() => {
      jest.spyOn(Tracking, 'event');

      factory({
        step: STEPS.commitCiFile,
      });
    });

    it('tracks an event', () => {
      expect(Tracking.event).toHaveBeenCalledWith(
        EXPERIMENT_NAME,
        `${STEPS.commitCiFile}_displayed`,
        {
          context: {
            schema: TRACKING_CONTEXT_SCHEMA,
            data: dummyContext,
          },
        },
      );
    });
  });

  describe('When updating the component', () => {
    beforeEach(() => {
      factory({
        step: STEPS.runningPipeline,
      });

      jest.spyOn(Tracking, 'event');

      wrapper.setProps({ step: STEPS.successPipeline });
    });

    it('tracks an event', () => {
      expect(Tracking.event).toHaveBeenCalledWith(
        EXPERIMENT_NAME,
        `${STEPS.successPipeline}_displayed`,
        {
          context: {
            schema: TRACKING_CONTEXT_SCHEMA,
            data: dummyContext,
          },
        },
      );
    });
  });

  describe('When dismissing a popover', () => {
    beforeEach(() => {
      factory({
        step: STEPS.commitCiFile,
      });

      jest.spyOn(Cookies, 'set');
      jest.spyOn(Tracking, 'event');

      findButton().vm.$emit('click');
    });

    it('sets a cookie', () => {
      expect(Cookies.set).toHaveBeenCalledWith(
        EXPERIMENT_NAME,
        { commit_ci_file: true, data: dummyContext },
        { expires: 365 },
      );
    });

    it('removes the popover', () => {
      expect(findPopover().exists()).toBe(false);
    });

    it('tracks an event', () => {
      expect(Tracking.event).toHaveBeenCalledWith(
        EXPERIMENT_NAME,
        `${STEPS.commitCiFile}_dismissed`,
        {
          context: {
            schema: TRACKING_CONTEXT_SCHEMA,
            data: dummyContext,
          },
        },
      );
    });
  });

  describe('Code Quality Walkthrough Step component', () => {
    describe.each(Object.values(STEPS))('%s step', (step) => {
      it(`renders ${step === STEPS.troubleshootJob ? 'an alert' : 'a popover'}`, () => {
        const options = { step };
        if ([STEPS.successPipeline, STEPS.failedPipeline].includes(step)) {
          options.link = dummyLink;
        }
        factory(options);

        expect(wrapper.element).toMatchSnapshot();
      });
    });
  });
});

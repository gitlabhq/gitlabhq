import { GlAlert } from '@gitlab/ui';
import { shallowMount, mount } from '@vue/test-utils';
import { makeMockUserCalloutDismisser } from 'helpers/mock_user_callout_dismisser';
import InputsAdoptionBanner from '~/ci/common/pipeline_inputs/inputs_adoption_banner.vue';

describe('InputsAdoptionAlert', () => {
  let wrapper;
  let userCalloutDismissSpy;

  const defaultProvide = {
    canViewPipelineEditor: true,
    pipelineEditorPath: '/root/project/-/ci/editor',
  };

  const createComponent = ({
    mountFn = shallowMount,
    provide = {},
    shouldShowCallout = true,
  } = {}) => {
    userCalloutDismissSpy = jest.fn();

    wrapper = mountFn(InputsAdoptionBanner, {
      propsData: {
        featureName: 'feature_name',
      },
      provide: {
        ...defaultProvide,
        ...provide,
      },
      stubs: {
        UserCalloutDismisser: makeMockUserCalloutDismisser({
          dismiss: userCalloutDismissSpy,
          shouldShowCallout,
        }),
      },
    });
  };

  const findAlert = () => wrapper.findComponent(GlAlert);

  describe('on render', () => {
    describe('alert', () => {
      beforeEach(() => {
        createComponent();
      });

      it('renders the alert', () => {
        expect(findAlert().exists()).toBe(true);
      });

      it('sets the correct props', () => {
        expect(findAlert().props()).toMatchObject({
          variant: 'tip',
        });
      });
    });

    describe('content rendering', () => {
      beforeEach(() => {
        createComponent({ mountFn: mount });
      });

      it('displays the correct message content', () => {
        const message = wrapper.text();
        expect(message).toContain('Using inputs to control pipeline behavior');
        expect(message).toContain('Consider updating your pipelines to use inputs instead');
      });

      it('formats the "inputs" text with code tags', () => {
        const codeTags = wrapper.findAll('code');
        expect(codeTags).toHaveLength(2);
        codeTags.wrappers.forEach((code) => {
          expect(code.text()).toBe('inputs');
        });
      });

      it('does not display the pipeline editor button if not available', () => {
        createComponent({ provide: { canViewPipelineEditor: false } });
        const alertText = findAlert().text();

        expect(alertText).not.toContain('Go to the pipeline editor');
      });
    });

    describe('dismissing the alert', () => {
      it('calls the dismiss callback', () => {
        createComponent();
        findAlert().vm.$emit('dismiss');

        expect(userCalloutDismissSpy).toHaveBeenCalled();
      });
    });

    describe('when the alert has been dismissed', () => {
      it('does not show the alert', () => {
        createComponent({
          shouldShowCallout: false,
        });
        expect(findAlert().exists()).toBe(false);
      });
    });
  });
});

import { nextTick } from 'vue';
import { GlAlert } from '@gitlab/ui';
import { shallowMount, mount } from '@vue/test-utils';
import InputsAdoptionBanner from '~/ci/common/pipeline_inputs/inputs_adoption_banner.vue';

describe('InputsAdoptionBanner', () => {
  let wrapper;

  const defaultProvide = {
    canViewPipelineEditor: true,
    pipelineEditorPath: '/root/project/-/ci/editor',
  };

  const createComponent = ({ mountFn = shallowMount, provide = {} } = {}) => {
    wrapper = mountFn(InputsAdoptionBanner, {
      provide: {
        ...defaultProvide,
        ...provide,
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
          primaryButtonLink: defaultProvide.pipelineEditorPath,
          primaryButtonText: 'Go to the pipeline editor',
          secondaryButtonLink: '/help/ci/yaml/inputs',
          secondaryButtonText: 'Learn more',
        });
      });

      it('dismisses the alert when dismiss event is emitted', async () => {
        expect(findAlert().exists()).toBe(true);

        findAlert().vm.$emit('dismiss');
        await nextTick();

        expect(findAlert().exists()).toBe(false);
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
  });
});

import { GlButton, GlSprintf } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import PipelineEditorFileNav from '~/ci/pipeline_editor/components/file_nav/pipeline_editor_file_nav.vue';
import PipelineEditorEmptyState from '~/ci/pipeline_editor/components/ui/pipeline_editor_empty_state.vue';

describe('Pipeline editor empty state', () => {
  let wrapper;
  const defaultProvide = {
    emptyStateIllustrationPath: 'my/svg/path',
    usesExternalConfig: false,
  };

  const createComponent = ({ provide } = {}) => {
    wrapper = shallowMount(PipelineEditorEmptyState, {
      provide: { ...defaultProvide, ...provide },
    });
  };

  const findFileNav = () => wrapper.findComponent(PipelineEditorFileNav);
  const findSvgImage = () => wrapper.find('img');
  const findTitle = () => wrapper.find('h1');
  const findExternalCiInstructions = () => wrapper.find('p');
  const findConfirmButton = () => wrapper.findComponent(GlButton);
  const findDescription = () => wrapper.findComponent(GlSprintf);

  describe('when project uses an external CI config', () => {
    beforeEach(() => {
      createComponent({
        provide: { usesExternalConfig: true },
      });
    });

    it('renders an svg image', () => {
      expect(findSvgImage().exists()).toBe(true);
    });

    it('renders the correct title and instructions', () => {
      expect(findTitle().exists()).toBe(true);
      expect(findExternalCiInstructions().exists()).toBe(true);

      expect(findExternalCiInstructions().html()).toContain(
        wrapper.vm.$options.i18n.externalCiInstructions,
      );
      expect(findTitle().text()).toBe(wrapper.vm.$options.i18n.externalCiNote);
    });

    it('does not render the CTA button', () => {
      expect(findConfirmButton().exists()).toBe(false);
    });
  });

  describe('when project uses an accessible CI config', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders an svg image', () => {
      expect(findSvgImage().exists()).toBe(true);
    });

    it('renders a title', () => {
      expect(findTitle().exists()).toBe(true);
      expect(findTitle().text()).toBe(wrapper.vm.$options.i18n.title);
    });

    it('renders a description', () => {
      expect(findDescription().exists()).toBe(true);
      expect(findDescription().html()).toContain(wrapper.vm.$options.i18n.body);
    });

    it('renders the file nav', () => {
      expect(findFileNav().exists()).toBe(true);
    });

    it('renders a CTA button', () => {
      expect(findConfirmButton().exists()).toBe(true);
      expect(findConfirmButton().text()).toBe(wrapper.vm.$options.i18n.btnText);
    });

    it('emits an event when clicking on the CTA', async () => {
      const expectedEvent = 'createEmptyConfigFile';
      expect(wrapper.emitted(expectedEvent)).toBeUndefined();

      await findConfirmButton().vm.$emit('click');
      expect(wrapper.emitted(expectedEvent)).toHaveLength(1);
    });
  });
});

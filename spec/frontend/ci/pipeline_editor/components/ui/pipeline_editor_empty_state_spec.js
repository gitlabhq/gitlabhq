import { GlButton, GlSprintf, GlEmptyState } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import PipelineEditorFileNav from '~/ci/pipeline_editor/components/file_nav/pipeline_editor_file_nav.vue';
import PipelineEditorEmptyState from '~/ci/pipeline_editor/components/ui/pipeline_editor_empty_state.vue';

const emptyStateIllustrationPath = 'illustrations/empty-state/empty-pipeline-md.svg';

describe('Pipeline editor empty state', () => {
  let wrapper;
  const defaultProvide = {
    emptyStateIllustrationPath,
    usesExternalConfig: false,
  };

  const createComponent = ({ provide } = {}) => {
    wrapper = shallowMount(PipelineEditorEmptyState, {
      provide: { ...defaultProvide, ...provide },
      stubs: { GlSprintf },
    });
  };

  const findFileNav = () => wrapper.findComponent(PipelineEditorFileNav);
  const findEmptyState = () => wrapper.findComponent(GlEmptyState);
  const findConfirmButton = () => findEmptyState().findComponent(GlButton);

  describe('when project uses an external CI config', () => {
    beforeEach(() => {
      createComponent({
        provide: { usesExternalConfig: true },
      });
    });

    it('renders an empty state', () => {
      expect(findEmptyState().props()).toMatchObject({
        description: wrapper.vm.$options.i18n.externalCiInstructions,
        primaryButtonText: null,
        svgPath: emptyStateIllustrationPath,
        title: "This project's pipeline configuration is located outside this repository",
      });
    });
  });

  describe('when project uses an accessible CI config', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders the file nav', () => {
      expect(findFileNav().exists()).toBe(true);
    });

    it('renders an empty state', () => {
      expect(findEmptyState().exists()).toBe(true);
    });

    it('renders correct title and illustration', () => {
      expect(findEmptyState().props('svgPath')).toBe(emptyStateIllustrationPath);
      expect(findEmptyState().props('title')).toBe('Optimize your workflow with CI/CD Pipelines');
    });

    it('renders the correct instructions', () => {
      expect(findEmptyState().text()).toContain(
        'Create a new .gitlab-ci.yml file at the root of the repository to get started.',
      );
    });

    it('emits an event when clicking on the CTA', async () => {
      const expectedEvent = 'createEmptyConfigFile';
      expect(wrapper.emitted(expectedEvent)).toBeUndefined();

      await findConfirmButton().vm.$emit('click');
      expect(wrapper.emitted(expectedEvent)).toHaveLength(1);
    });
  });
});

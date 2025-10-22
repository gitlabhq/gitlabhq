import { GlButton, GlSprintf, GlEmptyState } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import PipelineEditorFileNav from '~/ci/pipeline_editor/components/file_nav/pipeline_editor_file_nav.vue';
import PipelineEditorEmptyState from '~/ci/pipeline_editor/components/ui/pipeline_editor_empty_state.vue';
import ExternalConfigEmptyState from '~/ci/common/empty_state/external_config_empty_state.vue';

const emptyStateIllustrationPath = 'illustrations/empty-state/empty-pipeline-md.svg';

describe('Pipeline editor empty state', () => {
  let wrapper;
  const defaultProvide = {
    emptyStateIllustrationPath,
    usesExternalConfig: false,
    newPipelinePath: '',
  };

  const createComponent = ({ provide } = {}) => {
    wrapper = shallowMount(PipelineEditorEmptyState, {
      provide: { ...defaultProvide, ...provide },
      stubs: { GlSprintf },
    });
  };

  const findFileNav = () => wrapper.findComponent(PipelineEditorFileNav);
  const findEmptyState = () => wrapper.findComponent(GlEmptyState);
  const findExternalConfigEmptyState = () => wrapper.findComponent(ExternalConfigEmptyState);
  const findConfirmButton = () => findEmptyState().findComponent(GlButton);

  describe('when project uses an external CI config', () => {
    const newPipelinePath = '/path-to-new-pipeline';
    beforeEach(() => {
      createComponent({
        provide: { usesExternalConfig: true, newPipelinePath },
      });
    });

    it('renders the external config empty state', () => {
      expect(findExternalConfigEmptyState().exists()).toBe(true);
    });

    it('provides newPipelinePath to the external config empty state', () => {
      expect(findExternalConfigEmptyState().props('newPipelinePath')).toBe(newPipelinePath);
    });

    it('renders the file nav', () => {
      expect(findFileNav().exists()).toBe(true);
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
      expect(findExternalConfigEmptyState().exists()).toBe(false);
    });

    it('renders correct title and illustration', () => {
      expect(findEmptyState().props('svgPath')).toBe(emptyStateIllustrationPath);
      expect(findEmptyState().props('title')).toBe(
        'Configure a pipeline to automate your builds, tests, and deployments',
      );
    });

    it('renders the correct instructions', () => {
      expect(findEmptyState().text()).toContain(
        'Create a .gitlab-ci.yml file in your repository to configure and run your first pipeline.',
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

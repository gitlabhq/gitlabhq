import '~/commons';
import { shallowMount } from '@vue/test-utils';
import EmptyState from '~/ci/pipelines_page/components/empty_state/no_ci_empty_state.vue';
import PipelinesEmptyState from '~/ci/common/empty_state/pipelines_empty_state.vue';
import PipelinesCiTemplates from '~/ci/pipelines_page/components/empty_state/pipelines_ci_templates.vue';

describe('Pipelines Empty State', () => {
  let wrapper;

  const findPipelinesEmptyState = () => wrapper.findComponent(PipelinesEmptyState);
  const pipelinesCiTemplates = () => wrapper.findComponent(PipelinesCiTemplates);

  const createWrapper = (provide = {}) => {
    wrapper = shallowMount(EmptyState, {
      provide: {
        pipelineEditorPath: '',
        suggestedCiTemplates: [],
        anyRunnersAvailable: true,
        ciRunnerSettingsPath: '',
        canCreatePipeline: true,
        ...provide,
      },
    });
  };

  describe('when user can configure CI', () => {
    beforeEach(() => {
      createWrapper();
    });

    it('should render the CI/CD templates', () => {
      expect(pipelinesCiTemplates().exists()).toBe(true);
    });
  });

  describe('when user cannot configure CI', () => {
    beforeEach(() => {
      createWrapper({ canCreatePipeline: false });
    });

    it('renders the pipelines empty state with the no-CI description', () => {
      expect(findPipelinesEmptyState().props()).toMatchObject({
        description: 'This project is not currently set up to run pipelines.',
      });
    });

    it('does not render the CI/CD templates', () => {
      expect(pipelinesCiTemplates().exists()).toBe(false);
    });
  });
});

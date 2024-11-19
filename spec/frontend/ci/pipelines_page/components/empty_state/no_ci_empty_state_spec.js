import '~/commons';
import { shallowMount } from '@vue/test-utils';
import { GlEmptyState } from '@gitlab/ui';
import EmptyState from '~/ci/pipelines_page/components/empty_state/no_ci_empty_state.vue';
import PipelinesCiTemplates from '~/ci/pipelines_page/components/empty_state/pipelines_ci_templates.vue';

describe('Pipelines Empty State', () => {
  let wrapper;

  const findEmptyState = () => wrapper.findComponent(GlEmptyState);
  const findButton = () => wrapper.find('a');
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
      propsData: {
        emptyStateSvgPath: 'foo.svg',
      },
      stubs: {
        GlEmptyState,
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

    it('should render empty state SVG', () => {
      expect(findEmptyState().props('svgPath')).toBe('foo.svg');
    });

    it('should render empty state header', () => {
      expect(wrapper.text()).toBe('This project is not currently set up to run pipelines.');
    });

    it('should not render a link', () => {
      expect(findButton().exists()).toBe(false);
    });
  });
});

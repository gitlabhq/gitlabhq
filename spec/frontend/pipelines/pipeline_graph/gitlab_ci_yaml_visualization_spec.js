import { shallowMount } from '@vue/test-utils';
import { GlTab } from '@gitlab/ui';
import { yamlString } from './mock_data';
import PipelineGraph from '~/pipelines/components/pipeline_graph/pipeline_graph.vue';
import GitlabCiYamlVisualization from '~/pipelines/components/pipeline_graph/gitlab_ci_yaml_visualization.vue';

describe('gitlab yaml visualization component', () => {
  const defaultProps = { blobData: yamlString };
  let wrapper;

  const createComponent = props => {
    return shallowMount(GitlabCiYamlVisualization, {
      propsData: {
        ...defaultProps,
        ...props,
      },
    });
  };

  const findGlTabComponents = () => wrapper.findAll(GlTab);
  const findPipelineGraph = () => wrapper.find(PipelineGraph);

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('tabs component', () => {
    beforeEach(() => {
      wrapper = createComponent();
    });

    it('renders the file and visualization tabs', () => {
      expect(findGlTabComponents()).toHaveLength(2);
    });
  });

  describe('graph component', () => {
    beforeEach(() => {
      wrapper = createComponent();
    });

    it('is hidden by default', () => {
      expect(findPipelineGraph().exists()).toBe(false);
    });
  });
});

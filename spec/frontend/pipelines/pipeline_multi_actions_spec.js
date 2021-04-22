import { GlDropdown, GlSprintf } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import PipelineMultiActions from '~/pipelines/components/pipelines_list/pipeline_multi_actions.vue';

describe('Pipeline Multi Actions Dropdown', () => {
  let wrapper;

  const artifactItemTestId = 'artifact-item';

  const defaultProps = {
    artifacts: [
      {
        name: 'job my-artifact',
        path: '/download/path',
      },
      {
        name: 'job-2 my-artifact-2',
        path: '/download/path-two',
      },
    ],
  };

  const createComponent = (props = defaultProps) => {
    wrapper = extendedWrapper(
      shallowMount(PipelineMultiActions, {
        propsData: {
          ...defaultProps,
          ...props,
        },
        stubs: {
          GlSprintf,
        },
      }),
    );
  };

  const findDropdown = () => wrapper.findComponent(GlDropdown);
  const findAllArtifactItems = () => wrapper.findAllByTestId(artifactItemTestId);
  const findFirstArtifactItem = () => wrapper.findByTestId(artifactItemTestId);

  beforeEach(() => {
    createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('should render the dropdown', () => {
    expect(findDropdown().exists()).toBe(true);
  });

  describe('Artifacts', () => {
    it('should render all the provided artifacts', () => {
      expect(findAllArtifactItems()).toHaveLength(defaultProps.artifacts.length);
    });

    it('should render the correct artifact name and path', () => {
      expect(findFirstArtifactItem().attributes('href')).toBe(defaultProps.artifacts[0].path);

      expect(findFirstArtifactItem().text()).toBe(
        `Download ${defaultProps.artifacts[0].name} artifact`,
      );
    });
  });
});

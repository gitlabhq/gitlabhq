import { GlDropdown, GlDropdownItem, GlSprintf } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import PipelineArtifacts from '~/pipelines/components/pipelines_list/pipelines_artifacts.vue';

describe('Pipelines Artifacts dropdown', () => {
  let wrapper;

  const artifacts = [
    {
      name: 'job my-artifact',
      path: '/download/path',
    },
    {
      name: 'job-2 my-artifact-2',
      path: '/download/path-two',
    },
  ];
  const pipelineId = 108;

  const createComponent = ({ mockArtifacts = artifacts } = {}) => {
    wrapper = shallowMount(PipelineArtifacts, {
      propsData: {
        pipelineId,
        artifacts: mockArtifacts,
      },
      stubs: {
        GlSprintf,
      },
    });
  };

  const findDropdown = () => wrapper.findComponent(GlDropdown);
  const findFirstGlDropdownItem = () => wrapper.findComponent(GlDropdownItem);
  const findAllGlDropdownItems = () =>
    wrapper.findComponent(GlDropdown).findAllComponents(GlDropdownItem);

  it('should render a dropdown with all the provided artifacts', () => {
    createComponent();

    expect(findAllGlDropdownItems()).toHaveLength(artifacts.length);
  });

  it('should render a link with the provided path', () => {
    createComponent();

    expect(findFirstGlDropdownItem().attributes('href')).toBe(artifacts[0].path);
    expect(findFirstGlDropdownItem().text()).toBe(artifacts[0].name);
  });

  describe('with no artifacts', () => {
    it('should not render the dropdown', () => {
      createComponent({ mockArtifacts: [] });

      expect(findDropdown().exists()).toBe(false);
    });
  });
});

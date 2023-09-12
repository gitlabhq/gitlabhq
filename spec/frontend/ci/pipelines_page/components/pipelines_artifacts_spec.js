import {
  GlDisclosureDropdown,
  GlDisclosureDropdownItem,
  GlDisclosureDropdownGroup,
  GlSprintf,
} from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import PipelineArtifacts from '~/ci/pipelines_page/components/pipelines_artifacts.vue';

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
        GlDisclosureDropdown,
        GlDisclosureDropdownItem,
        GlDisclosureDropdownGroup,
      },
    });
  };

  const findGlDropdown = () => wrapper.findComponent(GlDisclosureDropdown);
  const findFirstGlDropdownItem = () => wrapper.findComponent(GlDisclosureDropdownItem);

  it('should render a dropdown with all the provided artifacts', () => {
    createComponent();

    const [{ items }] = findGlDropdown().props('items');
    expect(items).toHaveLength(artifacts.length);
  });

  it('should render a link with the provided path', () => {
    createComponent();

    expect(findFirstGlDropdownItem().props('item').href).toBe(artifacts[0].path);
    expect(findFirstGlDropdownItem().text()).toBe(artifacts[0].name);
  });

  describe('with no artifacts', () => {
    it('should not render the dropdown', () => {
      createComponent({ mockArtifacts: [] });

      expect(findGlDropdown().exists()).toBe(false);
    });
  });
});

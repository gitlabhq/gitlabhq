import { GlDropdown, GlDropdownItem, GlSprintf } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import PipelineArtifacts from '~/pipelines/components/pipelines_list/pipelines_artifacts.vue';

describe('Pipelines Artifacts dropdown', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = shallowMount(PipelineArtifacts, {
      propsData: {
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
      },
      stubs: {
        GlSprintf,
      },
    });
  };

  const findFirstGlDropdownItem = () => wrapper.find(GlDropdownItem);
  const findAllGlDropdownItems = () => wrapper.find(GlDropdown).findAll(GlDropdownItem);

  beforeEach(() => {
    createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  it('should render a dropdown with all the provided artifacts', () => {
    expect(findAllGlDropdownItems()).toHaveLength(2);
  });

  it('should render a link with the provided path', () => {
    expect(findFirstGlDropdownItem().attributes('href')).toBe('/download/path');

    expect(findFirstGlDropdownItem().text()).toBe('Download job my-artifact artifact');
  });
});

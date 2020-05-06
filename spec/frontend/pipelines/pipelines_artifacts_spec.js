import { shallowMount } from '@vue/test-utils';
import PipelineArtifacts from '~/pipelines/components/pipelines_artifacts.vue';
import { GlLink } from '@gitlab/ui';

describe('Pipelines Artifacts dropdown', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = shallowMount(PipelineArtifacts, {
      propsData: {
        artifacts: [
          {
            name: 'artifact',
            path: '/download/path',
          },
          {
            name: 'artifact two',
            path: '/download/path-two',
          },
        ],
      },
    });
  };

  const findGlLink = () => wrapper.find(GlLink);
  const findAllGlLinks = () => wrapper.find('.dropdown-menu').findAll(GlLink);

  beforeEach(() => {
    createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  it('should render a dropdown with all the provided artifacts', () => {
    expect(findAllGlLinks()).toHaveLength(2);
  });

  it('should render a link with the provided path', () => {
    expect(findGlLink().attributes('href')).toEqual('/download/path');

    expect(findGlLink().text()).toContain('artifact');
  });
});

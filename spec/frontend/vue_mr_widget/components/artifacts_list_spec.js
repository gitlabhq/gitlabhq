import { shallowMount } from '@vue/test-utils';
import { GlLink } from '@gitlab/ui';
import ArtifactsList from '~/vue_merge_request_widget/components/artifacts_list.vue';
import { artifactsList } from './mock_data';

describe('Artifacts List', () => {
  let wrapper;

  const data = {
    artifacts: artifactsList,
  };

  const mountComponent = props => {
    wrapper = shallowMount(ArtifactsList, {
      propsData: {
        ...props,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  beforeEach(() => {
    mountComponent(data);
  });

  it('renders list of artifacts', () => {
    expect(wrapper.findAll('tbody tr').length).toEqual(data.artifacts.length);
  });

  it('renders link for the artifact', () => {
    expect(wrapper.find(GlLink).attributes('href')).toEqual(data.artifacts[0].url);
  });

  it('renders artifact name', () => {
    expect(wrapper.find(GlLink).text()).toEqual(data.artifacts[0].text);
  });

  it('renders job url', () => {
    expect(
      wrapper
        .findAll(GlLink)
        .at(1)
        .attributes('href'),
    ).toEqual(data.artifacts[0].job_path);
  });

  it('renders job name', () => {
    expect(
      wrapper
        .findAll(GlLink)
        .at(1)
        .text(),
    ).toEqual(data.artifacts[0].job_name);
  });
});

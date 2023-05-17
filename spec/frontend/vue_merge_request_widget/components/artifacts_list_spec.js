import { GlLink } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import ArtifactsList from '~/vue_merge_request_widget/components/artifacts_list.vue';
import { artifacts } from '../mock_data';

describe('Artifacts List', () => {
  let wrapper;

  const data = {
    artifacts,
  };

  const mountComponent = (props) => {
    wrapper = shallowMount(ArtifactsList, {
      propsData: {
        ...props,
      },
    });
  };

  beforeEach(() => {
    mountComponent(data);
  });

  it('renders list of artifacts', () => {
    expect(wrapper.findAll('tbody tr').length).toEqual(data.artifacts.length);
  });

  it('renders link for the artifact', () => {
    expect(wrapper.findComponent(GlLink).attributes('href')).toEqual(data.artifacts[0].url);
  });

  it('renders artifact name', () => {
    expect(wrapper.findComponent(GlLink).text()).toEqual(data.artifacts[0].text);
  });

  it('renders job url', () => {
    expect(wrapper.findAllComponents(GlLink).at(1).attributes('href')).toEqual(
      data.artifacts[0].job_path,
    );
  });

  it('renders job name', () => {
    expect(wrapper.findAllComponents(GlLink).at(1).text()).toEqual(data.artifacts[0].job_name);
  });
});

import { GlButton } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import ExternalConfigEmptyState from '~/ci/common/empty_state/external_config_empty_state.vue';
import PipelinesEmptyState from '~/ci/common/empty_state/pipelines_empty_state.vue';

describe('ExternalConfigEmptyState', () => {
  let wrapper;

  const createComponent = ({ propsData = {} } = {}) => {
    wrapper = shallowMount(ExternalConfigEmptyState, {
      propsData,
    });
  };

  const findPipelinesEmptyState = () => wrapper.findComponent(PipelinesEmptyState);
  const findButton = () => wrapper.findComponent(GlButton);

  it('renders the empty state with the title and description', () => {
    createComponent();

    expect(findPipelinesEmptyState().props()).toMatchObject({
      title: "This project's pipeline configuration is located outside this repository",
      description:
        "To view or edit the pipeline configuration, check your project's CI/CD settings for the external file location, then navigate to that project or repository.",
    });
  });

  it('does not render the button if newPipelinePath is not provided', () => {
    createComponent();

    expect(findButton().exists()).toBe(false);
  });

  it('renders the button if newPipelinePath is provided', () => {
    const newPipelinePath = '/path-to-new-pipeline';
    createComponent({ propsData: { newPipelinePath } });

    expect(findButton().props('href')).toBe(newPipelinePath);
    expect(findButton().text()).toBe('New pipeline');
  });
});

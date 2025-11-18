import { GlEmptyState, GlButton } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import ExternalConfigEmptyState from '~/ci/common/empty_state/external_config_empty_state.vue';

const emptyStateIllustrationPath = 'illustrations/empty-state/empty-pipeline-md.svg';

describe('ExternalConfigEmptyState', () => {
  let wrapper;

  const createComponent = ({ provide = {}, propsData = {} } = {}) => {
    wrapper = shallowMount(ExternalConfigEmptyState, {
      propsData,
      provide: {
        emptyStateIllustrationPath,
        ...provide,
      },
    });
  };

  const findEmptyState = () => wrapper.findComponent(GlEmptyState);
  const findButton = () => wrapper.findComponent(GlButton);

  it('renders the empty state with correct props', () => {
    createComponent();

    expect(findEmptyState().props()).toMatchObject({
      title: "This project's pipeline configuration is located outside this repository",
      description:
        "To view or edit the pipeline configuration, check your project's CI/CD settings for the external file location, then navigate to that project or repository.",
      svgPath: emptyStateIllustrationPath,
    });
  });

  it('does not render the button if newPipelinePath is not provided', () => {
    createComponent();

    expect(findButton().exists()).toBe(false);
  });

  it('renders the button if newPipelinePath is provided', () => {
    const newPipelinePath = '/path-to-new-pipeline';
    createComponent({ propsData: { newPipelinePath } });

    expect(findButton().attributes('href')).toBe(newPipelinePath);
    expect(findButton().text()).toBe('New pipeline');
  });
});

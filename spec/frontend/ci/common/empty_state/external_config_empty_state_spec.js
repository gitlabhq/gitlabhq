import { GlEmptyState } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import ExternalConfigEmptyState from '~/ci/common/empty_state/external_config_empty_state.vue';

const emptyStateIllustrationPath = 'illustrations/empty-state/empty-pipeline-md.svg';

describe('ExternalConfigEmptyState', () => {
  let wrapper;

  const createComponent = (provide = {}) => {
    wrapper = shallowMount(ExternalConfigEmptyState, {
      provide: {
        emptyStateIllustrationPath,
        ...provide,
      },
    });
  };

  const findEmptyState = () => wrapper.findComponent(GlEmptyState);

  beforeEach(() => {
    createComponent();
  });

  it('renders the empty state with correct props', () => {
    expect(findEmptyState().props()).toMatchObject({
      title: "This project's pipeline configuration is located outside this repository",
      description:
        "To view or edit the pipeline configuration, check your project's CI/CD settings for the external file location, then navigate to that project or repository.",
      svgPath: emptyStateIllustrationPath,
    });
  });
});

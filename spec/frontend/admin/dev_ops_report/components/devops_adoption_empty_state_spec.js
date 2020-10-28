import { shallowMount } from '@vue/test-utils';
import { GlEmptyState, GlButton } from '@gitlab/ui';
import DevopsAdoptionEmptyState from '~/admin/dev_ops_report/components/devops_adoption_empty_state.vue';
import { DEVOPS_ADOPTION_STRINGS } from '~/admin/dev_ops_report/constants';

const emptyStateSvgPath = 'illustrations/monitoring/getting_started.svg';

describe('DevopsAdoptionEmptyState', () => {
  let wrapper;

  const createComponent = (options = {}) => {
    const { stubs = {} } = options;
    return shallowMount(DevopsAdoptionEmptyState, {
      provide: {
        emptyStateSvgPath,
      },
      stubs,
    });
  };

  const findEmptyState = () => wrapper.find(GlEmptyState);
  const findEmptyStateAction = () => findEmptyState().find(GlButton);

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  it('contains the correct svg', () => {
    wrapper = createComponent();

    expect(findEmptyState().props('svgPath')).toBe(emptyStateSvgPath);
  });

  it('contains the correct text', () => {
    wrapper = createComponent();

    const emptyState = findEmptyState();

    expect(emptyState.props('title')).toBe(DEVOPS_ADOPTION_STRINGS.emptyState.title);
    expect(emptyState.props('description')).toBe(DEVOPS_ADOPTION_STRINGS.emptyState.description);
  });

  it('contains an overridden action button', () => {
    wrapper = createComponent({ stubs: { GlEmptyState } });

    const actionButton = findEmptyStateAction();

    expect(actionButton.exists()).toBe(true);
    expect(actionButton.text()).toBe(DEVOPS_ADOPTION_STRINGS.emptyState.button);
  });
});

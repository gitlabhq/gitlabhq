import { mountExtended } from 'helpers/vue_test_utils_helper';
import { s__ } from '~/locale';
import EmptyState from '~/environments/components/empty_state.vue';
import { ENVIRONMENTS_SCOPE } from '~/environments/constants';

const HELP_PATH = '/help';

describe('~/environments/components/empty_state.vue', () => {
  let wrapper;

  const createWrapper = ({ propsData = {} } = {}) =>
    mountExtended(EmptyState, {
      propsData: {
        scope: ENVIRONMENTS_SCOPE.AVAILABLE,
        helpPath: HELP_PATH,
        ...propsData,
      },
    });

  afterEach(() => {
    wrapper.destroy();
  });

  it('shows an empty state for available environments', () => {
    wrapper = createWrapper();

    const title = wrapper.findByRole('heading', {
      name: s__("Environments|You don't have any environments."),
    });

    expect(title.exists()).toBe(true);
  });

  it('shows an empty state for stopped environments', () => {
    wrapper = createWrapper({ propsData: { scope: ENVIRONMENTS_SCOPE.STOPPED } });

    const title = wrapper.findByRole('heading', {
      name: s__("Environments|You don't have any stopped environments."),
    });

    expect(title.exists()).toBe(true);
  });

  it('shows a link to the the help path', () => {
    wrapper = createWrapper();

    const link = wrapper.findByRole('link', {
      name: s__('Environments|How do I create an environment?'),
    });

    expect(link.attributes('href')).toBe(HELP_PATH);
  });
});

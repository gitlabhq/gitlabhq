import { mountExtended } from 'helpers/vue_test_utils_helper';
import { s__ } from '~/locale';
import EmptyState from '~/environments/components/empty_state.vue';
import { ENVIRONMENTS_SCOPE } from '~/environments/constants';

const HELP_PATH = '/help';
const NEW_PATH = '/new';

describe('~/environments/components/empty_state.vue', () => {
  let wrapper;

  const findNewEnvironmentLink = () =>
    wrapper.findByRole('link', {
      name: s__('Environments|New environment'),
    });

  const findDocsLink = () =>
    wrapper.findByRole('link', {
      name: s__('Environments|How do I create an environment?'),
    });

  const createWrapper = ({ propsData = {} } = {}) =>
    mountExtended(EmptyState, {
      propsData: {
        scope: ENVIRONMENTS_SCOPE.AVAILABLE,
        helpPath: HELP_PATH,
        ...propsData,
      },
      provide: { newEnvironmentPath: NEW_PATH },
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

    const link = findDocsLink();

    expect(link.attributes('href')).toBe(HELP_PATH);
  });

  it('hides a link to creating a new environment', () => {
    const link = findNewEnvironmentLink();

    expect(link.exists()).toBe(false);
  });

  describe('with search term', () => {
    beforeEach(() => {
      wrapper = createWrapper({ propsData: { hasTerm: true } });
    });

    it('should show text about searching', () => {
      const header = wrapper.findByRole('heading', {
        name: s__('Environments|No results found'),
      });

      expect(header.exists()).toBe(true);

      const text = wrapper.findByText(s__('Environments|Edit your search and try again'));

      expect(text.exists()).toBe(true);
    });

    it('hides the documentation link', () => {
      const link = findDocsLink();

      expect(link.exists()).toBe(false);
    });

    it('shows a link to create a new environment', () => {
      const link = findNewEnvironmentLink();

      expect(link.attributes('href')).toBe(NEW_PATH);
    });
  });
});

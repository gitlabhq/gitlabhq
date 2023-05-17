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
      name: s__('Environments|Create an environment'),
    });

  const findDocsLink = () =>
    wrapper.findByRole('link', {
      name: 'Learn more',
    });

  const finfEnablingReviewButton = () =>
    wrapper.findByRole('button', {
      name: s__('Environments|Enable review apps'),
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

  describe('without search term', () => {
    beforeEach(() => {
      wrapper = createWrapper();
    });

    it('shows an empty state environments', () => {
      const title = wrapper.findByRole('heading', {
        name: s__('Environments|Get started with environments'),
      });

      expect(title.exists()).toBe(true);
    });

    it('shows a link to the the help path', () => {
      const link = findDocsLink();

      expect(link.attributes('href')).toBe(HELP_PATH);
    });

    it('shows a link to creating a new environment', () => {
      const link = findNewEnvironmentLink();

      expect(link.attributes('href')).toBe(NEW_PATH);
    });

    it('shows a button to enable review apps', () => {
      const button = finfEnablingReviewButton();

      expect(button.exists()).toBe(true);
    });

    it('should emit enable review', () => {
      const button = finfEnablingReviewButton();

      button.vm.$emit('click');

      expect(wrapper.emitted('enable-review')).toBeDefined();
    });
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

    it('hide a link to create a new environment', () => {
      const link = findNewEnvironmentLink();

      expect(link.exists()).toBe(false);
    });

    it('hide a button to enable review apps', () => {
      const button = finfEnablingReviewButton();

      expect(button.exists()).toBe(false);
    });
  });
});

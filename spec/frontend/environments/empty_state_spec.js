import { GlEmptyState, GlLink, GlSprintf } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import EmptyResult from '~/vue_shared/components/empty_result.vue';
import EmptyState from '~/environments/components/empty_state.vue';
import { ENVIRONMENTS_SCOPE } from '~/environments/constants';

const HELP_PATH = '/help';
const NEW_PATH = '/new';

describe('~/environments/components/empty_state.vue', () => {
  let wrapper;

  const findEmptyState = () => wrapper.findComponent(GlEmptyState);
  const findDocsLink = () => wrapper.findComponent(GlLink);
  const findNewEnvironmentButton = () => wrapper.findByTestId('new-environment-button');
  const findEnablingReviewButton = () => wrapper.findByTestId('enable-review-button');

  const createWrapper = ({ propsData = {} } = {}) =>
    shallowMountExtended(EmptyState, {
      propsData: {
        scope: ENVIRONMENTS_SCOPE.AVAILABLE,
        helpPath: HELP_PATH,
        ...propsData,
      },
      provide: { newEnvironmentPath: NEW_PATH },
      stubs: { GlSprintf },
    });

  describe('without search term', () => {
    beforeEach(() => {
      wrapper = createWrapper();
    });

    it('shows an empty state environments with the correct title', () => {
      expect(findEmptyState().props('title')).toBe('Get started with environments');
    });

    it('shows a link to the the help path', () => {
      expect(findDocsLink().attributes('href')).toBe(HELP_PATH);
    });

    it('shows a button to create a new environment', () => {
      expect(findNewEnvironmentButton().attributes('href')).toBe(NEW_PATH);
    });

    it('shows a button to enable review apps', () => {
      expect(findEnablingReviewButton().exists()).toBe(true);
    });

    it('emits enable review event', () => {
      findEnablingReviewButton().vm.$emit('click');

      expect(wrapper.emitted('enable-review')).toBeDefined();
    });
  });

  describe('with search term', () => {
    beforeEach(() => {
      wrapper = createWrapper({ propsData: { hasTerm: true } });
    });

    it('should show EmptyResult component', () => {
      expect(wrapper.findComponent(EmptyResult).exists()).toBe(true);
    });

    it('hides the documentation link', () => {
      expect(findDocsLink().exists()).toBe(false);
    });

    it('hides a button to create a new environment', () => {
      expect(findNewEnvironmentButton().exists()).toBe(false);
    });

    it('hides a button to enable review apps', () => {
      expect(findEnablingReviewButton().exists()).toBe(false);
    });
  });
});

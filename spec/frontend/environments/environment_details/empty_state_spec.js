import { GlEmptyState, GlSprintf } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import EmptyState from '~/environments/environment_details/empty_state.vue';
import { environmentsHelpPagePath } from '~/environments/environment_details/constants';

describe('~/environments/environment_details/empty_state.vue', () => {
  let wrapper;

  const createWrapper = () => {
    return shallowMount(EmptyState, { stubs: { GlEmptyState, GlSprintf } });
  };

  const findGlEmptyState = () => wrapper.findComponent(GlEmptyState);

  describe('when Empty State is rendered for environment details page', () => {
    beforeEach(() => {
      wrapper = createWrapper();
    });

    it('should render the proper title', () => {
      expect(findGlEmptyState().props('title')).toBe('No deployment history');
    });

    it('should render the proper description', () => {
      expect(wrapper.text()).toContain(
        'Add an environment:name to your CI/CD jobs to register a deployment action. Learn more about environments.',
      );
    });

    it('should render GlEmptyState component with correct props', () => {
      expect(findGlEmptyState().props().primaryButtonText).toBe('Read more');
      expect(findGlEmptyState().props().primaryButtonLink).toBe(environmentsHelpPagePath);
    });
  });
});

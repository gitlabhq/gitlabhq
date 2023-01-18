import { GlEmptyState } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import EmptyState from '~/environments/environment_details/empty_state.vue';
import {
  translations,
  environmentsHelpPagePath,
  codeBlockPlaceholders,
} from '~/environments/environment_details/constants';

describe('~/environments/environment_details/empty_state.vue', () => {
  let wrapper;

  const createWrapper = () => {
    return mountExtended(EmptyState);
  };

  describe('when Empty State is rendered for environment details page', () => {
    beforeEach(() => {
      wrapper = createWrapper();
    });

    it('should render the proper title', () => {
      expect(wrapper.text()).toContain(translations.emptyStateTitle);
    });

    it('should render GlEmptyState component with correct props', () => {
      const glEmptyStateComponent = wrapper.findComponent(GlEmptyState);
      expect(glEmptyStateComponent.props().primaryButtonText).toBe(
        translations.emptyStatePrimaryButton,
      );
      expect(glEmptyStateComponent.props().primaryButtonLink).toBe(environmentsHelpPagePath);
    });

    it('should render formatted description', () => {
      expect(wrapper.text()).not.toContain(codeBlockPlaceholders.code[0]);
      expect(wrapper.text()).not.toContain(codeBlockPlaceholders.code[1]);
    });
  });
});

import { GlEmptyState } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import EmptyState, { i18n } from '~/pipelines/components/test_reports/empty_state.vue';

describe('Test report empty state', () => {
  let wrapper;

  const findEmptyState = () => wrapper.findComponent(GlEmptyState);

  const createComponent = ({ hasTestReport = true } = {}) => {
    wrapper = shallowMount(EmptyState, {
      provide: {
        emptyStateImagePath: '/image/path',
        hasTestReport,
      },
      stubs: {
        GlEmptyState,
      },
    });
  };

  describe('when pipeline has a test report', () => {
    it('should render empty test report message', () => {
      createComponent();

      expect(findEmptyState().props()).toMatchObject({
        primaryButtonText: i18n.noTestsButton,
        description: i18n.noTestsDescription,
        title: i18n.noTestsTitle,
      });
    });
  });

  describe('when pipeline does not have a test report', () => {
    it('should render no test report message', () => {
      createComponent({ hasTestReport: false });

      expect(findEmptyState().props()).toMatchObject({
        primaryButtonText: i18n.noReportsButton,
        description: i18n.noReportsDescription,
        title: i18n.noReportsTitle,
      });
    });
  });
});

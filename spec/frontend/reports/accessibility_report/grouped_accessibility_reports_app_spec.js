import { mount, createLocalVue } from '@vue/test-utils';
import Vuex from 'vuex';
import GroupedAccessibilityReportsApp from '~/reports/accessibility_report/grouped_accessibility_reports_app.vue';
import AccessibilityIssueBody from '~/reports/accessibility_report/components/accessibility_issue_body.vue';
import { getStoreConfig } from '~/reports/accessibility_report/store';
import { mockReport } from './mock_data';

const localVue = createLocalVue();
localVue.use(Vuex);

describe('Grouped accessibility reports app', () => {
  const Component = localVue.extend(GroupedAccessibilityReportsApp);
  let wrapper;
  let mockStore;

  const mountComponent = () => {
    wrapper = mount(Component, {
      store: mockStore,
      localVue,
      propsData: {
        endpoint: 'endpoint.json',
      },
    });
  };

  const findHeader = () => wrapper.find('[data-testid="report-section-code-text"]');

  beforeEach(() => {
    mockStore = new Vuex.Store({
      ...getStoreConfig(),
      actions: { fetchReport: () => {}, setEndpoint: () => {} },
    });

    mountComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  describe('while loading', () => {
    beforeEach(() => {
      mockStore.state.isLoading = true;
      mountComponent();
    });

    it('renders loading state', () => {
      expect(findHeader().text()).toEqual('Accessibility scanning results are being parsed');
    });
  });

  describe('with error', () => {
    beforeEach(() => {
      mockStore.state.isLoading = false;
      mockStore.state.hasError = true;
      mountComponent();
    });

    it('renders error state', () => {
      expect(findHeader().text()).toEqual('Accessibility scanning failed loading results');
    });
  });

  describe('with a report', () => {
    describe('with no issues', () => {
      beforeEach(() => {
        mockStore.state.report = {
          summary: {
            errored: 0,
          },
        };
      });

      it('renders no issues header', () => {
        expect(findHeader().text()).toContain(
          'Accessibility scanning detected no issues for the source branch only',
        );
      });
    });

    describe('with one issue', () => {
      beforeEach(() => {
        mockStore.state.report = {
          summary: {
            errored: 1,
          },
        };
      });

      it('renders one issue header', () => {
        expect(findHeader().text()).toContain(
          'Accessibility scanning detected 1 issue for the source branch only',
        );
      });
    });

    describe('with multiple issues', () => {
      beforeEach(() => {
        mockStore.state.report = {
          summary: {
            errored: 2,
          },
        };
      });

      it('renders multiple issues header', () => {
        expect(findHeader().text()).toContain(
          'Accessibility scanning detected 2 issues for the source branch only',
        );
      });
    });

    describe('with issues to show', () => {
      beforeEach(() => {
        mockStore.state.report = mockReport;
      });

      it('renders custom accessibility issue body', () => {
        const issueBody = wrapper.find(AccessibilityIssueBody);

        expect(issueBody.props('issue').code).toBe(mockReport.new_errors[0].code);
        expect(issueBody.props('issue').message).toBe(mockReport.new_errors[0].message);
        expect(issueBody.props('isNew')).toBe(true);
      });
    });
  });
});

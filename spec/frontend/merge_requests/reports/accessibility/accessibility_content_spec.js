import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import AccessibilityContent from '~/merge_requests/reports/accessibility/accessibility_content.vue';
import ReportSection from '~/merge_requests/reports/components/report_section.vue';

describe('AccessibilityContent', () => {
  let wrapper;

  const SECTIONS = [{ header: 'New', children: [{ text: 'An error', icon: { name: 'failed' } }] }];

  const findReportSection = () => wrapper.findComponent(ReportSection);

  const createComponent = (provide = {}) => {
    wrapper = shallowMountExtended(AccessibilityContent, {
      provide: {
        isAccessibilityLoading: false,
        statusMessage: '',
        errorMessage: '',
        errorCount: 5,
        statusIconName: 'warning',
        sections: SECTIONS,
        ...provide,
      },
    });
  };

  it('passes the injected state through to ReportSection', () => {
    createComponent({ isAccessibilityLoading: true });

    expect(findReportSection().props()).toMatchObject({
      isLoading: true,
      loadingText: 'Accessibility scanning results are being parsed',
      statusIconName: 'warning',
      sections: SECTIONS,
    });
  });

  it.each([
    [
      'the error count when there is no message',
      {},
      'Accessibility scanning detected %{strong_start}5%{strong_end} issues for the source branch only',
    ],
    ['the error message', { errorMessage: 'Failed to load' }, 'Failed to load'],
    [
      'the status message ahead of the error message',
      { statusMessage: 'Not available', errorMessage: 'Failed to load' },
      'Not available',
    ],
  ])('summarises %s', (_, provide, expected) => {
    createComponent(provide);

    expect(findReportSection().props('summary').title).toBe(expected);
  });
});

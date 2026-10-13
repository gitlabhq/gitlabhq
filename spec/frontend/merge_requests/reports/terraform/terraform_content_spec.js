import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import TerraformContent from '~/merge_requests/reports/terraform/terraform_content.vue';
import ReportSection from '~/merge_requests/reports/components/report_section.vue';

describe('TerraformContent', () => {
  let wrapper;

  const SECTIONS = [{ children: [{ text: 'A report', icon: { name: 'success' } }] }];
  const REPORT_SUMMARY = { title: '1 report', subtitle: '2 failed' };

  const findReportSection = () => wrapper.findComponent(ReportSection);

  const createComponent = (provide = {}) => {
    wrapper = shallowMountExtended(TerraformContent, {
      provide: {
        isTerraformLoading: false,
        statusMessage: '',
        reportSummary: REPORT_SUMMARY,
        statusIconName: 'warning',
        sections: SECTIONS,
        ...provide,
      },
    });
  };

  it('passes the injected state through to ReportSection', () => {
    createComponent({ isTerraformLoading: true });

    expect(findReportSection().props()).toMatchObject({
      isLoading: true,
      loadingText: 'Loading Terraform reports…',
      statusIconName: 'warning',
      sections: SECTIONS,
    });
  });

  it.each([
    ['the report summary when there is no status message', {}, REPORT_SUMMARY],
    [
      'the status message when there is one',
      { statusMessage: 'Not available' },
      { title: 'Not available' },
    ],
  ])('summarises %s', (_, provide, expected) => {
    createComponent(provide);

    expect(findReportSection().props('summary')).toEqual(expected);
  });
});

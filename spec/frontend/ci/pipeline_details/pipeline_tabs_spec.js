import { createAppOptions } from '~/ci/pipeline_details/pipeline_tabs';

jest.mock('~/lib/utils/url_utility', () => ({
  removeParams: () => 'gitlab.com',
  joinPaths: () => {},
  setUrlFragment: () => {},
}));

jest.mock('~/ci/pipeline_details/utils', () => ({
  getPipelineDefaultTab: () => '',
}));

describe('~/ci/pipeline_details/pipeline_tabs.js', () => {
  describe('createAppOptions', () => {
    const SELECTOR = 'SELECTOR';

    let el;

    const createElement = () => {
      el = document.createElement('div');
      el.id = SELECTOR;
      el.dataset.canGenerateCodequalityReports = 'true';
      el.dataset.codequalityReportDownloadPath = 'codequalityReportDownloadPath';
      el.dataset.downloadablePathForReportType = 'downloadablePathForReportType';
      el.dataset.exposeSecurityDashboard = 'true';
      el.dataset.exposeLicenseScanningData = 'true';
      el.dataset.failedJobsCount = 1;
      el.dataset.graphqlResourceEtag = 'graphqlResourceEtag';
      el.dataset.pipelineIid = '123';
      el.dataset.pipelineProjectPath = 'pipelineProjectPath';

      document.body.appendChild(el);
    };

    afterEach(() => {
      el = null;
    });

    it("extracts the properties from the element's dataset", () => {
      createElement();
      const options = createAppOptions(`#${SELECTOR}`, null);

      expect(options.el).toEqual(el);
      expect(options.provide).toMatchObject({
        canGenerateCodequalityReports: true,
        codequalityReportDownloadPath: 'codequalityReportDownloadPath',
        downloadablePathForReportType: 'downloadablePathForReportType',
        exposeSecurityDashboard: true,
        exposeLicenseScanningData: true,
        failedJobsCount: '1',
        graphqlResourceEtag: 'graphqlResourceEtag',
        pipelineIid: '123',
        pipelineProjectPath: 'pipelineProjectPath',
      });
    });

    it('returns `null` if el does not exist', () => {
      expect(createAppOptions('foo', null)).toBe(null);
    });
  });
});

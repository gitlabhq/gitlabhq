import { mount } from '@vue/test-utils';
import Api from '~/api';
import Flash from '~/flash';
import SecurityReportsApp from '~/vue_shared/security_reports/security_reports_app.vue';

jest.mock('~/flash');

describe('Security reports app', () => {
  let wrapper;
  let mrTabsMock;

  const props = {
    pipelineId: 123,
    projectId: 456,
    securityReportsDocsPath: '/docs',
  };

  const createComponent = () => {
    wrapper = mount(SecurityReportsApp, {
      propsData: { ...props },
    });
  };

  const anyParams = expect.any(Object);

  const findPipelinesTabAnchor = () => wrapper.find('[data-testid="show-pipelines"]');
  const findHelpLink = () => wrapper.find('[data-testid="help"]');
  const setupMrTabsMock = () => {
    mrTabsMock = { tabShown: jest.fn() };
    window.mrTabs = mrTabsMock;
  };
  const setupMockJobArtifact = reportType => {
    jest
      .spyOn(Api, 'pipelineJobs')
      .mockResolvedValue({ data: [{ artifacts: [{ file_type: reportType }] }] });
  };

  afterEach(() => {
    wrapper.destroy();
    delete window.mrTabs;
  });

  describe.each(SecurityReportsApp.reportTypes)('given a report type %p', reportType => {
    beforeEach(() => {
      window.mrTabs = { tabShown: jest.fn() };
      setupMockJobArtifact(reportType);
      createComponent();
      return wrapper.vm.$nextTick();
    });

    it('calls the pipelineJobs API correctly', () => {
      expect(Api.pipelineJobs).toHaveBeenCalledTimes(1);
      expect(Api.pipelineJobs).toHaveBeenCalledWith(props.projectId, props.pipelineId, anyParams);
    });

    it('renders the expected message', () => {
      expect(wrapper.text()).toMatchInterpolatedText(SecurityReportsApp.i18n.scansHaveRun);
    });

    describe('clicking the anchor to the pipelines tab', () => {
      beforeEach(() => {
        setupMrTabsMock();
        findPipelinesTabAnchor().trigger('click');
      });

      it('calls the mrTabs.tabShown global', () => {
        expect(mrTabsMock.tabShown.mock.calls).toEqual([['pipelines']]);
      });
    });

    it('renders a help link', () => {
      expect(findHelpLink().attributes()).toMatchObject({
        href: props.securityReportsDocsPath,
      });
    });
  });

  describe('given a report type "foo"', () => {
    beforeEach(() => {
      setupMockJobArtifact('foo');
      createComponent();
      return wrapper.vm.$nextTick();
    });

    it('calls the pipelineJobs API correctly', () => {
      expect(Api.pipelineJobs).toHaveBeenCalledTimes(1);
      expect(Api.pipelineJobs).toHaveBeenCalledWith(props.projectId, props.pipelineId, anyParams);
    });

    it('renders nothing', () => {
      expect(wrapper.html()).toBe('');
    });
  });

  describe('security artifacts on last page of multi-page response', () => {
    const numPages = 3;

    beforeEach(() => {
      jest
        .spyOn(Api, 'pipelineJobs')
        .mockImplementation(async (projectId, pipelineId, { page }) => {
          const requestedPage = parseInt(page, 10);
          if (requestedPage < numPages) {
            return {
              // Some jobs with no relevant artifacts
              data: [{}, {}],
              headers: { 'x-next-page': String(requestedPage + 1) },
            };
          } else if (requestedPage === numPages) {
            return {
              data: [{ artifacts: [{ file_type: SecurityReportsApp.reportTypes[0] }] }],
            };
          }

          throw new Error('Test failed due to request of non-existent jobs page');
        });

      createComponent();
      return wrapper.vm.$nextTick();
    });

    it('fetches all pages', () => {
      expect(Api.pipelineJobs).toHaveBeenCalledTimes(numPages);
    });

    it('renders the expected message', () => {
      expect(wrapper.text()).toMatchInterpolatedText(SecurityReportsApp.i18n.scansHaveRun);
    });
  });

  describe('given an error from the API', () => {
    let error;

    beforeEach(() => {
      error = new Error('an error');
      jest.spyOn(Api, 'pipelineJobs').mockRejectedValue(error);
      createComponent();
      return wrapper.vm.$nextTick();
    });

    it('calls the pipelineJobs API correctly', () => {
      expect(Api.pipelineJobs).toHaveBeenCalledTimes(1);
      expect(Api.pipelineJobs).toHaveBeenCalledWith(props.projectId, props.pipelineId, anyParams);
    });

    it('renders nothing', () => {
      expect(wrapper.html()).toBe('');
    });

    it('calls Flash correctly', () => {
      expect(Flash.mock.calls).toEqual([
        [
          {
            message: SecurityReportsApp.i18n.apiError,
            captureError: true,
            error,
          },
        ],
      ]);
    });
  });
});

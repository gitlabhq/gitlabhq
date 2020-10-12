import { mount } from '@vue/test-utils';
import Api from '~/api';
import Flash from '~/flash';
import SecurityReportsApp from '~/vue_shared/security_reports/security_reports_app.vue';

jest.mock('~/flash');

describe('Grouped security reports app', () => {
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
    });

    it('calls the pipelineJobs API correctly', () => {
      expect(Api.pipelineJobs).toHaveBeenCalledWith(props.projectId, props.pipelineId);
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
    });

    it('calls the pipelineJobs API correctly', () => {
      expect(Api.pipelineJobs).toHaveBeenCalledWith(props.projectId, props.pipelineId);
    });

    it('renders nothing', () => {
      expect(wrapper.html()).toBe('');
    });
  });

  describe('given an error from the API', () => {
    let error;

    beforeEach(() => {
      error = new Error('an error');
      jest.spyOn(Api, 'pipelineJobs').mockRejectedValue(error);
      createComponent();
    });

    it('calls the pipelineJobs API correctly', () => {
      expect(Api.pipelineJobs).toHaveBeenCalledWith(props.projectId, props.pipelineId);
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

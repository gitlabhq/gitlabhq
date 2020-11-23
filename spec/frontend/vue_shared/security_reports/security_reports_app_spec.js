import { mount, createLocalVue } from '@vue/test-utils';
import MockAdapter from 'axios-mock-adapter';
import { merge } from 'lodash';
import Vuex from 'vuex';
import { trimText } from 'helpers/text_helper';
import waitForPromises from 'helpers/wait_for_promises';
import {
  sastDiffSuccessMock,
  secretScanningDiffSuccessMock,
} from 'jest/vue_shared/security_reports/mock_data';
import Api from '~/api';
import createFlash from '~/flash';
import axios from '~/lib/utils/axios_utils';
import {
  REPORT_TYPE_SAST,
  REPORT_TYPE_SECRET_DETECTION,
} from '~/vue_shared/security_reports/constants';
import SecurityReportsApp from '~/vue_shared/security_reports/security_reports_app.vue';

jest.mock('~/flash');

const localVue = createLocalVue();
localVue.use(Vuex);

const SAST_COMPARISON_PATH = '/sast.json';
const SECRET_SCANNING_COMPARISON_PATH = '/secret_detection.json';

describe('Security reports app', () => {
  let wrapper;

  const props = {
    pipelineId: 123,
    projectId: 456,
    securityReportsDocsPath: '/docs',
  };

  const createComponent = options => {
    wrapper = mount(
      SecurityReportsApp,
      merge(
        {
          localVue,
          propsData: { ...props },
        },
        options,
      ),
    );
  };

  const anyParams = expect.any(Object);

  const findPipelinesTabAnchor = () => wrapper.find('[data-testid="show-pipelines"]');
  const findHelpLink = () => wrapper.find('[data-testid="help"]');
  const setupMockJobArtifact = reportType => {
    jest
      .spyOn(Api, 'pipelineJobs')
      .mockResolvedValue({ data: [{ artifacts: [{ file_type: reportType }] }] });
  };
  const expectPipelinesTabAnchor = () => {
    const mrTabsMock = { tabShown: jest.fn() };
    window.mrTabs = mrTabsMock;
    findPipelinesTabAnchor().trigger('click');
    expect(mrTabsMock.tabShown.mock.calls).toEqual([['pipelines']]);
  };

  afterEach(() => {
    wrapper.destroy();
    delete window.mrTabs;
  });

  describe.each([false, true])(
    'given the coreSecurityMrWidgetCounts feature flag is %p',
    coreSecurityMrWidgetCounts => {
      const createComponentWithFlag = options =>
        createComponent(
          merge(
            {
              provide: {
                glFeatures: {
                  coreSecurityMrWidgetCounts,
                },
              },
            },
            options,
          ),
        );

      describe.each(SecurityReportsApp.reportTypes)('given a report type %p', reportType => {
        beforeEach(() => {
          window.mrTabs = { tabShown: jest.fn() };
          setupMockJobArtifact(reportType);
          createComponentWithFlag();
          return wrapper.vm.$nextTick();
        });

        it('calls the pipelineJobs API correctly', () => {
          expect(Api.pipelineJobs).toHaveBeenCalledTimes(1);
          expect(Api.pipelineJobs).toHaveBeenCalledWith(
            props.projectId,
            props.pipelineId,
            anyParams,
          );
        });

        it('renders the expected message', () => {
          expect(wrapper.text()).toMatchInterpolatedText(SecurityReportsApp.i18n.scansHaveRun);
        });

        describe('clicking the anchor to the pipelines tab', () => {
          it('calls the mrTabs.tabShown global', () => {
            expectPipelinesTabAnchor();
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
          createComponentWithFlag();
          return wrapper.vm.$nextTick();
        });

        it('calls the pipelineJobs API correctly', () => {
          expect(Api.pipelineJobs).toHaveBeenCalledTimes(1);
          expect(Api.pipelineJobs).toHaveBeenCalledWith(
            props.projectId,
            props.pipelineId,
            anyParams,
          );
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

          createComponentWithFlag();
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
          createComponentWithFlag();
          return wrapper.vm.$nextTick();
        });

        it('calls the pipelineJobs API correctly', () => {
          expect(Api.pipelineJobs).toHaveBeenCalledTimes(1);
          expect(Api.pipelineJobs).toHaveBeenCalledWith(
            props.projectId,
            props.pipelineId,
            anyParams,
          );
        });

        it('renders nothing', () => {
          expect(wrapper.html()).toBe('');
        });

        it('calls createFlash correctly', () => {
          expect(createFlash.mock.calls).toEqual([
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
    },
  );

  describe('given the coreSecurityMrWidgetCounts feature flag is enabled', () => {
    let mock;

    const createComponentWithFlagEnabled = options =>
      createComponent(
        merge(options, {
          provide: {
            glFeatures: {
              coreSecurityMrWidgetCounts: true,
            },
          },
        }),
      );

    beforeEach(() => {
      mock = new MockAdapter(axios);
    });

    afterEach(() => {
      mock.restore();
    });

    const SAST_SUCCESS_MESSAGE =
      'Security scanning detected 1 potential vulnerability 1 Critical 0 High and 0 Others';
    const SECRET_SCANNING_SUCCESS_MESSAGE =
      'Security scanning detected 2 potential vulnerabilities 1 Critical 1 High and 0 Others';
    describe.each`
      reportType                      | pathProp                          | path                               | successResponse                  | successMessage
      ${REPORT_TYPE_SAST}             | ${'sastComparisonPath'}           | ${SAST_COMPARISON_PATH}            | ${sastDiffSuccessMock}           | ${SAST_SUCCESS_MESSAGE}
      ${REPORT_TYPE_SECRET_DETECTION} | ${'secretScanningComparisonPath'} | ${SECRET_SCANNING_COMPARISON_PATH} | ${secretScanningDiffSuccessMock} | ${SECRET_SCANNING_SUCCESS_MESSAGE}
    `(
      'given a $pathProp and $reportType artifact',
      ({ reportType, pathProp, path, successResponse, successMessage }) => {
        beforeEach(() => {
          setupMockJobArtifact(reportType);
        });

        describe('when loading', () => {
          beforeEach(() => {
            mock = new MockAdapter(axios, { delayResponse: 1 });
            mock.onGet(path).replyOnce(200, successResponse);

            createComponentWithFlagEnabled({
              propsData: {
                [pathProp]: path,
              },
            });

            return waitForPromises();
          });

          it('should have loading message', () => {
            expect(wrapper.text()).toBe('Security scanning is loading');
          });

          it('should not render the pipeline tab anchor', () => {
            expect(findPipelinesTabAnchor().exists()).toBe(false);
          });
        });

        describe('when successfully loaded', () => {
          beforeEach(() => {
            mock.onGet(path).replyOnce(200, successResponse);

            createComponentWithFlagEnabled({
              propsData: {
                [pathProp]: path,
              },
            });

            return waitForPromises();
          });

          it('should show counts', () => {
            expect(trimText(wrapper.text())).toContain(successMessage);
          });

          it('should render the pipeline tab anchor', () => {
            expectPipelinesTabAnchor();
          });
        });

        describe('when an error occurs', () => {
          beforeEach(() => {
            mock.onGet(path).replyOnce(500);

            createComponentWithFlagEnabled({
              propsData: {
                [pathProp]: path,
              },
            });

            return waitForPromises();
          });

          it('should show error message', () => {
            expect(trimText(wrapper.text())).toContain('Loading resulted in an error');
          });

          it('should render the pipeline tab anchor', () => {
            expectPipelinesTabAnchor();
          });
        });
      },
    );
  });
});

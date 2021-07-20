import { mount } from '@vue/test-utils';
import MockAdapter from 'axios-mock-adapter';
import { merge } from 'lodash';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import Vuex from 'vuex';
import createMockApollo from 'helpers/mock_apollo_helper';
import { trimText } from 'helpers/text_helper';
import waitForPromises from 'helpers/wait_for_promises';
import {
  expectedDownloadDropdownPropsWithText,
  securityReportMergeRequestDownloadPathsQueryNoArtifactsResponse,
  securityReportMergeRequestDownloadPathsQueryResponse,
  sastDiffSuccessMock,
  secretScanningDiffSuccessMock,
} from 'jest/vue_shared/security_reports/mock_data';
import createFlash from '~/flash';
import axios from '~/lib/utils/axios_utils';
import HelpIcon from '~/vue_shared/security_reports/components/help_icon.vue';
import SecurityReportDownloadDropdown from '~/vue_shared/security_reports/components/security_report_download_dropdown.vue';
import {
  REPORT_TYPE_SAST,
  REPORT_TYPE_SECRET_DETECTION,
} from '~/vue_shared/security_reports/constants';
import securityReportMergeRequestDownloadPathsQuery from '~/vue_shared/security_reports/queries/security_report_merge_request_download_paths.query.graphql';
import SecurityReportsApp from '~/vue_shared/security_reports/security_reports_app.vue';

jest.mock('~/flash');

Vue.use(VueApollo);
Vue.use(Vuex);

const SAST_COMPARISON_PATH = '/sast.json';
const SECRET_SCANNING_COMPARISON_PATH = '/secret_detection.json';

describe('Security reports app', () => {
  let wrapper;

  const props = {
    pipelineId: 123,
    projectId: 456,
    securityReportsDocsPath: '/docs',
    discoverProjectSecurityPath: '/discoverProjectSecurityPath',
  };

  const createComponent = (options) => {
    wrapper = mount(
      SecurityReportsApp,
      merge(
        {
          propsData: { ...props },
          stubs: {
            HelpIcon: true,
          },
        },
        options,
      ),
    );
  };

  const pendingHandler = () => new Promise(() => {});
  const successHandler = () =>
    Promise.resolve({ data: securityReportMergeRequestDownloadPathsQueryResponse });
  const successEmptyHandler = () =>
    Promise.resolve({ data: securityReportMergeRequestDownloadPathsQueryNoArtifactsResponse });
  const failureHandler = () => Promise.resolve({ errors: [{ message: 'some error' }] });
  const createMockApolloProvider = (handler) => {
    const requestHandlers = [[securityReportMergeRequestDownloadPathsQuery, handler]];

    return createMockApollo(requestHandlers);
  };

  const findDownloadDropdown = () => wrapper.find(SecurityReportDownloadDropdown);
  const findHelpIconComponent = () => wrapper.find(HelpIcon);

  afterEach(() => {
    wrapper.destroy();
  });

  describe('given the artifacts query is loading', () => {
    beforeEach(() => {
      createComponent({
        apolloProvider: createMockApolloProvider(pendingHandler),
      });
    });

    // TODO: Remove this assertion as part of
    // https://gitlab.com/gitlab-org/gitlab/-/issues/273431
    it('initially renders nothing', () => {
      expect(wrapper.html()).toBe('');
    });
  });

  describe('given the artifacts query loads successfully', () => {
    beforeEach(() => {
      createComponent({
        apolloProvider: createMockApolloProvider(successHandler),
      });
    });

    it('renders the download dropdown', () => {
      expect(findDownloadDropdown().props()).toEqual(expectedDownloadDropdownPropsWithText);
    });

    it('renders the expected message', () => {
      expect(wrapper.text()).toContain(SecurityReportsApp.i18n.scansHaveRun);
    });

    it('renders a help link', () => {
      expect(findHelpIconComponent().props()).toEqual({
        helpPath: props.securityReportsDocsPath,
        discoverProjectSecurityPath: props.discoverProjectSecurityPath,
      });
    });
  });

  describe('given the artifacts query loads successfully with no artifacts', () => {
    beforeEach(() => {
      createComponent({
        apolloProvider: createMockApolloProvider(successEmptyHandler),
      });
    });

    // TODO: Remove this assertion as part of
    // https://gitlab.com/gitlab-org/gitlab/-/issues/273431
    it('initially renders nothing', () => {
      expect(wrapper.html()).toBe('');
    });
  });

  describe('given the artifacts query fails', () => {
    beforeEach(() => {
      createComponent({
        apolloProvider: createMockApolloProvider(failureHandler),
      });
    });

    it('calls createFlash correctly', () => {
      expect(createFlash).toHaveBeenCalledWith({
        message: SecurityReportsApp.i18n.apiError,
        captureError: true,
        error: expect.any(Error),
      });
    });

    // TODO: Remove this assertion as part of
    // https://gitlab.com/gitlab-org/gitlab/-/issues/273431
    it('renders nothing', () => {
      expect(wrapper.html()).toBe('');
    });
  });

  describe('given the coreSecurityMrWidgetCounts feature flag is enabled', () => {
    let mock;

    const createComponentWithFlagEnabled = (options) =>
      createComponent(
        merge(options, {
          provide: {
            glFeatures: {
              coreSecurityMrWidgetCounts: true,
            },
          },
          apolloProvider: createMockApolloProvider(successHandler),
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
      ({ pathProp, path, successResponse, successMessage }) => {
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
            expect(wrapper.text()).toContain('Security scanning is loading');
          });

          it('renders the download dropdown', () => {
            expect(findDownloadDropdown().props()).toEqual(expectedDownloadDropdownPropsWithText);
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

          it('renders the download dropdown', () => {
            expect(findDownloadDropdown().props()).toEqual(expectedDownloadDropdownPropsWithText);
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

          it('renders the download dropdown', () => {
            expect(findDownloadDropdown().props()).toEqual(expectedDownloadDropdownPropsWithText);
          });
        });

        describe('when the comparison endpoint is not provided', () => {
          beforeEach(() => {
            mock.onGet(path).replyOnce(500);

            createComponentWithFlagEnabled();

            return waitForPromises();
          });

          it('renders the basic scansHaveRun  message', () => {
            expect(wrapper.text()).toContain(SecurityReportsApp.i18n.scansHaveRun);
          });
        });
      },
    );
  });
});

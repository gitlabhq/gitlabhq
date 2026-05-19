import MockAdapter from 'axios-mock-adapter';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import { useMockInternalEventsTracking } from 'helpers/tracking_internal_events_helper';
import waitForPromises from 'helpers/wait_for_promises';
import axios from '~/lib/utils/axios_utils';
import Widget from '~/vue_merge_request_widget/components/widget/widget.vue';
import { EXTENSION_ICONS } from '~/vue_merge_request_widget/constants';

import codeQualityWidget from '~/vue_merge_request_widget/widgets/code_quality/index.vue';
import * as utils from '~/vue_merge_request_widget/widgets/code_quality/utils';
import {
  HTTP_STATUS_INTERNAL_SERVER_ERROR,
  HTTP_STATUS_NO_CONTENT,
  HTTP_STATUS_OK,
} from '~/lib/utils/http_status';
import {
  newFinding,
  resolvedFinding,
  responseNewFindings,
  responseResolvedFindings,
  responseNewAndResolvedFindings,
  responseNoFindings,
} from './mock_data';

jest.mock('~/sentry/sentry_browser_wrapper');

describe('Code Quality widget', () => {
  let wrapper;
  let mock;

  const DEFAULT_MR_PROPS = {
    codequalityReportsPath: '/project/-/merge_requests/1/codequality_reports',
    reportsTabPath: '/project/-/merge_requests/1/reports',
  };

  const mockApi = (statusCode, data) => {
    mock.onGet(DEFAULT_MR_PROPS.codequalityReportsPath).reply(statusCode, data, {});
  };

  const findWidget = () => wrapper.findComponent(Widget);
  const findSummary = () => wrapper.findByTestId('widget-extension-top-level-summary');
  const findToggleCollapsedButton = () => wrapper.findByTestId('toggle-button');

  const createComponent = ({ provide = {}, mrProps = {} } = {}) => {
    wrapper = mountExtended(codeQualityWidget, {
      provide: {
        glFeatures: { mrReportsTab: true },
        ...provide,
      },
      propsData: {
        mr: {
          ...DEFAULT_MR_PROPS,
          ...mrProps,
        },
      },
    });
  };

  beforeEach(() => {
    mock = new MockAdapter(axios);
  });

  afterEach(() => {
    mock.restore();
  });

  describe('summary', () => {
    it('displays loading text', () => {
      mockApi(HTTP_STATUS_NO_CONTENT, {});

      createComponent();

      expect(findSummary().text()).toBe('Code Quality is loading');
    });

    describe('when request fails', () => {
      beforeEach(async () => {
        mockApi(HTTP_STATUS_INTERNAL_SERVER_ERROR);

        createComponent();

        await waitForPromises();
      });

      it('displays error text', () => {
        expect(findSummary().text()).toBe('Code Quality failed to load results');
      });

      it('is not collapsible', () => {
        expect(findToggleCollapsedButton().exists()).toBe(false);
      });
    });

    describe('when request succeeds', () => {
      it.each`
        scenario               | response                          | message                                                          | statusIcon
        ${'no findings'}       | ${responseNoFindings}             | ${"Code Quality hasn't changed."}                                | ${'neutral'}
        ${'new findings'}      | ${responseNewFindings}            | ${'Code Quality scans found 1 new finding.'}                     | ${'warning'}
        ${'resolved findings'} | ${responseResolvedFindings}       | ${'Code Quality scans found 1 fixed finding.'}                   | ${'success'}
        ${'new and resolved'}  | ${responseNewAndResolvedFindings} | ${'Code Quality scans found 1 new finding and 1 fixed finding.'} | ${'warning'}
      `('displays correct summary for $scenario', async ({ response, message, statusIcon }) => {
        mockApi(HTTP_STATUS_OK, response);

        createComponent();

        await waitForPromises();

        expect(findSummary().text()).toBe(message);
        expect(findWidget().props('statusIconName')).toBe(EXTENSION_ICONS[statusIcon]);
      });
    });
  });

  describe('data fetching', () => {
    it('emits loaded event with new error count', async () => {
      mockApi(HTTP_STATUS_OK, responseNewFindings);

      createComponent();

      await waitForPromises();

      expect(wrapper.emitted('loaded')).toEqual([[1]]);
    });

    it('reports errors to Sentry', async () => {
      mockApi(HTTP_STATUS_INTERNAL_SERVER_ERROR);

      createComponent();

      await waitForPromises();

      expect(Sentry.captureException).toHaveBeenCalled();
    });
  });

  describe('action buttons', () => {
    describe('when reports tab path is provided', () => {
      beforeEach(async () => {
        mockApi(HTTP_STATUS_OK, responseNewFindings);
        createComponent();
        await waitForPromises();
      });

      it('displays the "View report" button', () => {
        const actionButtons = findWidget().props('actionButtons');

        expect(actionButtons).toHaveLength(1);
        expect(actionButtons[0]).toMatchObject({
          href: `${DEFAULT_MR_PROPS.reportsTabPath}/code-quality`,
          text: 'View report',
        });
      });

      it('onClick navigates to the reports tab without page reload', () => {
        const pushStateSpy = jest.spyOn(window.history, 'pushState');
        const dispatchEventSpy = jest.spyOn(window, 'dispatchEvent');
        const actionButtons = findWidget().props('actionButtons');
        const event = { preventDefault: jest.fn() };

        actionButtons[0].onClick(actionButtons[0], event);

        expect(event.preventDefault).toHaveBeenCalled();
        expect(pushStateSpy).toHaveBeenCalledWith(
          null,
          null,
          `${DEFAULT_MR_PROPS.reportsTabPath}/code-quality`,
        );
        expect(dispatchEventSpy).toHaveBeenCalledWith(expect.any(PopStateEvent));
      });

      it('should not be collapsible', () => {
        expect(findWidget().props('isCollapsible')).toBe(false);
      });
    });

    describe('when reports tab path is not provided', () => {
      beforeEach(async () => {
        mockApi(HTTP_STATUS_OK, responseNewFindings);
        createComponent({ mrProps: { reportsTabPath: undefined } });
        await waitForPromises();
      });

      it('does not display the "View report" button', () => {
        expect(findWidget().props('actionButtons')).toHaveLength(0);
      });

      it('is collapsible', () => {
        expect(findWidget().props('isCollapsible')).toBe(true);
      });
    });

    describe('tracking', () => {
      const { bindInternalEventDocument } = useMockInternalEventsTracking();

      it('onClick tracks click_view_report_on_merge_request_widget', async () => {
        mockApi(HTTP_STATUS_OK, responseNewFindings);

        createComponent();
        await waitForPromises();

        const { trackEventSpy } = bindInternalEventDocument(wrapper.element);

        const actionButtons = findWidget().props('actionButtons');
        const event = { preventDefault: jest.fn() };
        actionButtons[0].onClick(actionButtons[0], event);

        expect(trackEventSpy).toHaveBeenCalledWith(
          'click_view_report_on_merge_request_widget',
          { label: 'code_quality' },
          undefined,
        );
      });
    });
  });

  describe('when mrReportsTab feature flag is disabled', () => {
    const createComponentWithFeatureFlagDisabled = () => {
      createComponent({ provide: { glFeatures: { mrReportsTab: false } } });
    };

    describe('expanded data', () => {
      it('calls transformNewCodeQualityFinding with each new finding', async () => {
        jest.spyOn(utils, 'transformNewCodeQualityFinding');
        mockApi(HTTP_STATUS_OK, responseNewFindings);

        createComponentWithFeatureFlagDisabled();

        await waitForPromises();

        expect(utils.transformNewCodeQualityFinding).toHaveBeenCalledWith(newFinding, 0, [
          newFinding,
        ]);
      });

      it('calls transformResolvedCodeQualityFinding with each resolved finding', async () => {
        jest.spyOn(utils, 'transformResolvedCodeQualityFinding');
        mockApi(HTTP_STATUS_OK, responseResolvedFindings);

        createComponentWithFeatureFlagDisabled();

        await waitForPromises();

        expect(utils.transformResolvedCodeQualityFinding).toHaveBeenCalledWith(resolvedFinding, 0, [
          resolvedFinding,
        ]);
      });
    });
  });
});

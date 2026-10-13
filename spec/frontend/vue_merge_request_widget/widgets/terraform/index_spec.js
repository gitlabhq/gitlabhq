import MockAdapter from 'axios-mock-adapter';
import { useMockInternalEventsTracking } from 'helpers/tracking_internal_events_helper';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_INTERNAL_SERVER_ERROR, HTTP_STATUS_OK } from '~/lib/utils/http_status';
import Poll from '~/lib/utils/poll';
import Widget from '~/vue_merge_request_widget/components/widget/widget.vue';
import terraformExtension from '~/vue_merge_request_widget/widgets/terraform/index.vue';
import {
  plans,
  validPlanWithName,
  validPlanWithoutName,
  invalidPlanWithName,
  invalidPlanWithoutName,
  validPlanFewChanges,
  validPlanNoChanges,
} from '../../components/terraform/mock_data';

jest.mock('~/api.js');

describe('Terraform extension', () => {
  let wrapper;
  let mock;

  const endpoint = '/path/to/terraform/report.json';
  const reportsTabPath = '/path/to/merge_request/reports';

  const findWidget = () => wrapper.findComponent(Widget);
  const findListItem = (at) => wrapper.findAllByTestId('extension-list-item').at(at);
  const findActionButton = (at) => wrapper.findAllByTestId('extension-actions-button').at(at);

  const mockPollingApi = (response, body, header) => {
    mock.onGet(endpoint).reply(response, body, header);
  };

  const createComponent = ({ mrProps = {} } = {}) => {
    wrapper = mountExtended(terraformExtension, {
      propsData: {
        mr: {
          terraformReportsPath: endpoint,
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

  it('emits loaded event', async () => {
    mockPollingApi(HTTP_STATUS_OK, plans, {});

    createComponent();

    await waitForPromises();

    expect(wrapper.emitted('loaded')[0]).toContain(2);
  });

  describe('summary', () => {
    describe('while loading', () => {
      const loadingText = 'Loading Terraform reports…';

      it('should render loading text', async () => {
        mockPollingApi(HTTP_STATUS_OK, plans, {});
        createComponent();

        expect(wrapper.text()).toContain(loadingText);

        await waitForPromises();
        expect(wrapper.text()).not.toContain(loadingText);
      });
    });

    describe('when the fetching fails', () => {
      beforeEach(async () => {
        mockPollingApi(HTTP_STATUS_INTERNAL_SERVER_ERROR, null, {});
        createComponent();
        await axios.waitForAll();
      });

      it('shows the error text, and keeps a synthetic failed report to expand', async () => {
        expect(wrapper.text()).toContain('Failed to load Terraform reports');
        expect(findWidget().props('isCollapsible')).toBe(true);

        wrapper.findByTestId('toggle-button').trigger('click');
        await waitForPromises();

        expect(findListItem(0).text()).toContain('A Terraform report failed to generate.');
      });
    });

    describe('when the fetching succeeds', () => {
      describe.each`
        responseType                       | response                                                                    | summaryTitle                                              | summarySubtitle
        ${'1 invalid report'}              | ${{ 0: invalidPlanWithName }}                                               | ${'1 Terraform report failed to generate'}                | ${''}
        ${'2 valid reports'}               | ${{ 0: validPlanWithName, 1: validPlanWithName }}                           | ${'2 Terraform reports were generated in your pipelines'} | ${''}
        ${'1 valid and 2 invalid reports'} | ${{ 0: validPlanWithName, 1: invalidPlanWithName, 2: invalidPlanWithName }} | ${'Terraform report was generated in your pipelines'}     | ${'2 Terraform reports failed to generate'}
      `('and received $responseType', ({ response, summaryTitle, summarySubtitle }) => {
        beforeEach(async () => {
          mockPollingApi(HTTP_STATUS_OK, response, {});
          createComponent();
          await axios.waitForAll();
        });

        it(`should render correct summary text`, () => {
          expect(wrapper.text()).toContain(summaryTitle);

          if (summarySubtitle) {
            expect(wrapper.text()).toContain(summarySubtitle);
          }
        });
      });
    });
  });

  describe('expanded data in expected order', () => {
    const { bindInternalEventDocument } = useMockInternalEventsTracking();
    beforeEach(async () => {
      mockPollingApi(HTTP_STATUS_OK, plans, {});
      createComponent();
      await axios.waitForAll();

      wrapper.findByTestId('toggle-button').trigger('click');
    });

    describe.each`
      reportType                          | title                                                                     | subtitle                                                                                                                                                  | logLink                            | lineNumber
      ${'a valid report with name'}       | ${`The job ${validPlanWithName.job_name} generated a report.`}            | ${`Reported Resource Changes: ${validPlanWithName.create} to add, ${validPlanWithName.update} to change, ${validPlanWithName.delete} to delete`}          | ${validPlanWithName.job_path}      | ${0}
      ${'a valid report without name'}    | ${'A Terraform report was generated in your pipelines.'}                  | ${`Reported Resource Changes: ${validPlanWithoutName.create} to add, ${validPlanWithoutName.update} to change, ${validPlanWithoutName.delete} to delete`} | ${validPlanWithoutName.job_path}   | ${1}
      ${'a valid with few changes'}       | ${`The job ${validPlanFewChanges.job_name} generated a report.`}          | ${`Reported Resource Changes: ${validPlanFewChanges.create} to add, ${validPlanFewChanges.update} to change, ${validPlanFewChanges.delete} to delete`}    | ${validPlanFewChanges.job_path}    | ${2}
      ${'a valid with no changes'}        | ${`The job ${validPlanNoChanges.job_name} generated a report.`}           | ${`Reported Resource Changes: ${validPlanNoChanges.create} to add, ${validPlanNoChanges.update} to change, ${validPlanNoChanges.delete} to delete`}       | ${validPlanNoChanges.job_path}     | ${3}
      ${'an invalid report with name'}    | ${`The job ${invalidPlanWithName.job_name} failed to generate a report.`} | ${'Generating the report caused an error.'}                                                                                                               | ${invalidPlanWithName.job_path}    | ${4}
      ${'an invalid report without name'} | ${'A Terraform report failed to generate.'}                               | ${'Generating the report caused an error.'}                                                                                                               | ${invalidPlanWithoutName.job_path} | ${5}
    `('renders correct text for $reportType', ({ title, subtitle, logLink, lineNumber }) => {
      it('renders correct text', () => {
        expect(findListItem(lineNumber).text()).toContain(title);
        expect(findListItem(lineNumber).text()).toContain(subtitle);
      });

      it(`${logLink ? 'renders' : "doesn't render"} the log link`, () => {
        const logText = 'Full log';
        if (logLink) {
          expect(
            findListItem(lineNumber)
              .find('[data-testid="extension-actions-button"]')
              .attributes('href'),
          ).toBe(logLink);
        } else {
          expect(findListItem(lineNumber).text()).not.toContain(logText);
        }
      });
    });

    it('responds with the correct telemetry when the deeply nested "Full log" link is clicked', () => {
      const { trackEventSpy } = bindInternalEventDocument(wrapper.element);

      findActionButton(0).trigger('click');

      expect(trackEventSpy).toHaveBeenCalledWith('click_full_report_on_merge_request_widget', {
        label: 'terraform',
      });
    });

    it('keeps the small subtle styling on the supporting text', () => {
      expect(findListItem(0).find('.gl-text-sm.gl-text-subtle').text()).toBe(
        `Reported Resource Changes: ${validPlanWithName.create} to add, ${validPlanWithName.update} to change, ${validPlanWithName.delete} to delete`,
      );
    });
  });

  describe('"View report" button', () => {
    const { bindInternalEventDocument } = useMockInternalEventsTracking();

    beforeEach(async () => {
      mockPollingApi(HTTP_STATUS_OK, plans, {});
      createComponent({ mrProps: { reportsTabPath } });
      await axios.waitForAll();
    });

    it('replaces the collapse toggle with a link to the terraform report', () => {
      expect(findWidget().props('actionButtons')).toMatchObject([
        { text: 'View report', href: `${reportsTabPath}/terraform` },
      ]);
      expect(findWidget().props('isCollapsible')).toBe(false);
    });

    it('navigates to the report without a page reload, and tracks the click', () => {
      const { trackEventSpy } = bindInternalEventDocument(wrapper.element);
      const pushStateSpy = jest.spyOn(window.history, 'pushState');
      const dispatchEventSpy = jest.spyOn(window, 'dispatchEvent');
      const [button] = findWidget().props('actionButtons');
      const event = { preventDefault: jest.fn() };

      button.onClick(button, event);

      expect(event.preventDefault).toHaveBeenCalled();
      expect(trackEventSpy).toHaveBeenCalledWith(
        'click_view_report_on_merge_request_widget',
        { label: 'terraform' },
        undefined,
      );
      expect(pushStateSpy).toHaveBeenCalledWith(null, null, `${reportsTabPath}/terraform`);
      expect(dispatchEventSpy).toHaveBeenCalledWith(expect.any(PopStateEvent));
    });

    it('is absent, and the widget stays collapsible, without a reports tab', async () => {
      createComponent();
      await axios.waitForAll();

      expect(findWidget().props('actionButtons')).toHaveLength(0);
      expect(findWidget().props('isCollapsible')).toBe(true);
    });
  });

  describe('polling', () => {
    let pollRequest;

    beforeEach(() => {
      pollRequest = jest.spyOn(Poll.prototype, 'makeRequest');
    });

    afterEach(() => {
      pollRequest.mockRestore();
    });

    describe('successful poll', () => {
      beforeEach(async () => {
        mockPollingApi(HTTP_STATUS_OK, plans, {});
        createComponent();
        await axios.waitForAll();
      });

      it('does not make additional requests after poll is successful', () => {
        expect(pollRequest).toHaveBeenCalledTimes(1);
      });
    });

    describe('polling fails', () => {
      beforeEach(async () => {
        mockPollingApi(HTTP_STATUS_INTERNAL_SERVER_ERROR, null, {});
        createComponent();
        await axios.waitForAll();
      });

      it('renders the error text', () => {
        expect(wrapper.text()).toContain('Failed to load Terraform reports');
      });

      it('does not make additional requests after poll is unsuccessful', () => {
        expect(pollRequest).toHaveBeenCalledTimes(1);
      });
    });
  });
});

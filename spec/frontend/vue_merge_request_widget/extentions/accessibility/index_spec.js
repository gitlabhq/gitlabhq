import MockAdapter from 'axios-mock-adapter';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import { trimText } from 'helpers/text_helper';
import waitForPromises from 'helpers/wait_for_promises';
import api from '~/api';
import axios from '~/lib/utils/axios_utils';
import AccessibilityWidget from '~/vue_merge_request_widget/extensions/accessibility/index.vue';
import { HTTP_STATUS_INTERNAL_SERVER_ERROR, HTTP_STATUS_OK } from '~/lib/utils/http_status';
import { accessibilityReportResponseErrors, accessibilityReportResponseSuccess } from './mock_data';

describe('Accessibility widget', () => {
  let wrapper;
  let mock;

  const endpoint = '/root/repo/-/merge_requests/4/accessibility_reports.json';

  const mockApi = (statusCode, data) => {
    mock.onGet(endpoint).reply(statusCode, data, {});
  };

  const findToggleCollapsedButton = () => wrapper.findByTestId('toggle-button');
  const findAllExtensionListItems = () => wrapper.findAllByTestId('extension-list-item');

  const createComponent = () => {
    wrapper = mountExtended(AccessibilityWidget, {
      propsData: {
        mr: {
          accessibilityReportPath: endpoint,
        },
      },
    });
  };

  beforeEach(() => {
    jest.spyOn(api, 'trackRedisCounterEvent').mockImplementation(() => {});
    mock = new MockAdapter(axios);
    jest.spyOn(api, 'trackRedisCounterEvent').mockImplementation(() => {});
  });

  afterEach(() => {
    mock.restore();
  });

  describe('summary', () => {
    it('displays loading text', () => {
      mockApi(HTTP_STATUS_OK, accessibilityReportResponseErrors);

      createComponent();

      expect(wrapper.text()).toBe('Accessibility scanning results are being parsed');
    });

    it('displays failed loading text', async () => {
      mockApi(HTTP_STATUS_INTERNAL_SERVER_ERROR);

      createComponent();

      await waitForPromises();

      expect(wrapper.text()).toBe('Accessibility scanning failed loading results');
    });

    it('displays detected errors and is expandable', async () => {
      mockApi(HTTP_STATUS_OK, accessibilityReportResponseErrors);

      createComponent();

      await waitForPromises();

      expect(wrapper.text()).toBe(
        'Accessibility scanning detected 8 issues for the source branch only',
      );
      expect(findToggleCollapsedButton().exists()).toBe(true);
    });

    it('displays no detected errors and is not expandable', async () => {
      mockApi(HTTP_STATUS_OK, accessibilityReportResponseSuccess);

      createComponent();

      await waitForPromises();

      expect(wrapper.text()).toBe(
        'Accessibility scanning detected no issues for the source branch only',
      );
      expect(findToggleCollapsedButton().exists()).toBe(false);
    });
  });

  describe('expanded data', () => {
    beforeEach(async () => {
      mockApi(HTTP_STATUS_OK, accessibilityReportResponseErrors);

      createComponent();

      await waitForPromises();

      findToggleCollapsedButton().trigger('click');

      await waitForPromises();
    });

    it('displays all report list items in viewport', () => {
      expect(findAllExtensionListItems()).toHaveLength(7);
    });

    it('displays report list item formatted', () => {
      const text = {
        newError: trimText(findAllExtensionListItems().at(0).text()),
        resolvedError: trimText(findAllExtensionListItems().at(3).text()),
        existingError: trimText(findAllExtensionListItems().at(6).text()),
      };

      expect(text.newError).toBe(
        'New The accessibility scanning found an error of the following type: WCAG2AA.Principle2.Guideline2_4.2_4_1.H64.1 Learn more Message: Iframe element requires a non-empty title attribute that identifies the frame.',
      );
      expect(text.resolvedError).toBe(
        'The accessibility scanning found an error of the following type: WCAG2AA.Principle1.Guideline1_1.1_1_1.H30.2 Learn more Message: Img element is the only content of the link, but is missing alt text. The alt text should describe the purpose of the link.',
      );
      expect(text.existingError).toBe(
        'The accessibility scanning found an error of the following type: WCAG2AA.Principle1.Guideline1_1.1_1_1.H37 Learn more Message: Img element missing an alt attribute. Use the alt attribute to specify a short text alternative.',
      );
    });
  });
});

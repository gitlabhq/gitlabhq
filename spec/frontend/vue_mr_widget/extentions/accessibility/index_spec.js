import MockAdapter from 'axios-mock-adapter';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import { trimText } from 'helpers/text_helper';
import waitForPromises from 'helpers/wait_for_promises';
import axios from '~/lib/utils/axios_utils';
import extensionsContainer from '~/vue_merge_request_widget/components/extensions/container';
import { registerExtension } from '~/vue_merge_request_widget/components/extensions';
import accessibilityExtension from '~/vue_merge_request_widget/extensions/accessibility';
import httpStatusCodes from '~/lib/utils/http_status';
import { accessibilityReportResponseErrors, accessibilityReportResponseSuccess } from './mock_data';

describe('Accessibility extension', () => {
  let wrapper;
  let mock;

  registerExtension(accessibilityExtension);

  const endpoint = '/root/repo/-/merge_requests/4/accessibility_reports.json';

  const mockApi = (statusCode, data) => {
    mock.onGet(endpoint).reply(statusCode, data);
  };

  const findToggleCollapsedButton = () => wrapper.findByTestId('toggle-button');
  const findAllExtensionListItems = () => wrapper.findAllByTestId('extension-list-item');

  const createComponent = () => {
    wrapper = mountExtended(extensionsContainer, {
      propsData: {
        mr: {
          accessibilityReportPath: endpoint,
        },
      },
    });
  };

  beforeEach(() => {
    mock = new MockAdapter(axios);
  });

  afterEach(() => {
    wrapper.destroy();
    mock.restore();
  });

  describe('summary', () => {
    it('displays loading text', () => {
      mockApi(httpStatusCodes.OK, accessibilityReportResponseErrors);

      createComponent();

      expect(wrapper.text()).toBe('Accessibility scanning results are being parsed');
    });

    it('displays failed loading text', async () => {
      mockApi(httpStatusCodes.INTERNAL_SERVER_ERROR);

      createComponent();

      await waitForPromises();

      expect(wrapper.text()).toBe('Accessibility scanning failed loading results');
    });

    it('displays detected errors', async () => {
      mockApi(httpStatusCodes.OK, accessibilityReportResponseErrors);

      createComponent();

      await waitForPromises();

      expect(wrapper.text()).toBe(
        'Accessibility scanning detected 8 issues for the source branch only',
      );
    });

    it('displays no detected errors', async () => {
      mockApi(httpStatusCodes.OK, accessibilityReportResponseSuccess);

      createComponent();

      await waitForPromises();

      expect(wrapper.text()).toBe(
        'Accessibility scanning detected no issues for the source branch only',
      );
    });
  });

  describe('expanded data', () => {
    beforeEach(async () => {
      mockApi(httpStatusCodes.OK, accessibilityReportResponseErrors);

      createComponent();

      await waitForPromises();

      findToggleCollapsedButton().vm.$emit('click');

      await waitForPromises();
    });
    it('displays all report list items', async () => {
      expect(findAllExtensionListItems()).toHaveLength(10);
    });

    it('displays report list item formatted', () => {
      const text = {
        newError: trimText(findAllExtensionListItems().at(0).text()),
        resolvedError: findAllExtensionListItems().at(3).text(),
        existingError: trimText(findAllExtensionListItems().at(8).text()),
      };

      expect(text.newError).toBe(
        'New The accessibility scanning found an error of the following type: WCAG2AA.Principle2.Guideline2_4.2_4_1.H64.1 Learn more Message: Iframe element requires a non-empty title attribute that identifies the frame.',
      );
      expect(text.resolvedError).toBe(
        'The accessibility scanning found an error of the following type: WCAG2AA.Principle1.Guideline1_1.1_1_1.H30.2 Learn more Message: Img element is the only content of the link, but is missing alt text. The alt text should describe the purpose of the link.',
      );
      expect(text.existingError).toBe(
        'The accessibility scanning found an error of the following type: WCAG2AA.Principle2.Guideline2_4.2_4_1.H64.1 Learn more Message: Iframe element requires a non-empty title attribute that identifies the frame.',
      );
    });
  });
});

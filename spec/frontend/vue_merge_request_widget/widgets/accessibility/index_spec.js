import MockAdapter from 'axios-mock-adapter';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import { trimText } from 'helpers/text_helper';
import waitForPromises from 'helpers/wait_for_promises';
import api from '~/api';
import axios from '~/lib/utils/axios_utils';
import AccessibilityWidget from '~/vue_merge_request_widget/widgets/accessibility/index.vue';
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

  it('emits loaded event', async () => {
    mockApi(HTTP_STATUS_OK, accessibilityReportResponseErrors);

    createComponent();

    await waitForPromises();

    expect(wrapper.emitted('loaded')[0]).toContain(5);
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
        'Accessibility scanning detected 5 issues for the source branch only',
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
        firstNewError: trimText(findAllExtensionListItems().at(0).text()),
        secondNewError: trimText(findAllExtensionListItems().at(1).text()),
        thirdNewError: trimText(findAllExtensionListItems().at(2).text()),
        firstExistingError: trimText(findAllExtensionListItems().at(3).text()),
        secondExistingError: trimText(findAllExtensionListItems().at(4).text()),
        firstResolvedError: trimText(findAllExtensionListItems().at(5).text()),
        secondResolvedError: trimText(findAllExtensionListItems().at(6).text()),
      };

      expect(text.firstNewError).toBe(
        'New The accessibility scanning found an error of the following type: WCAG2AA.Principle2.Guideline2_4.2_4_1.H64.1 Message: Iframe element requires a non-empty title attribute that identifies the frame. Details Details',
      );
      expect(text.secondNewError).toBe(
        'The accessibility scanning found an error of the following type: WCAG2AA.Principle3.Guideline3_2.3_2_2.H32.2 Message: This form does not contain a submit button, which creates issues for those who cannot submit the form using the keyboard. Submit buttons are INPUT elements with type attribute &quot;submit&quot; or &quot;image&quot;, or BUTTON elements with type &quot;submit&quot; or omitted/invalid. Details Details',
      );
      expect(text.thirdNewError).toBe(
        'The accessibility scanning found an error of the following type: WCAG2AA.Principle2.Guideline2_4.2_4_1.H64.1 Message: Iframe element requires a non-empty title attribute that identifies the frame. Details Details',
      );
      expect(text.firstExistingError).toBe(
        'Not fixed The accessibility scanning found an error of the following type: WCAG2AA.Principle1.Guideline1_1.1_1_1.H30.2 Message: Img element is the only content of the link, but is missing alt text. The alt text should describe the purpose of the link. Details Details',
      );
      expect(text.secondExistingError).toBe(
        'The accessibility scanning found an error of the following type: WCAG2AA.Principle1.Guideline1_1.1_1_1.H37 Message: Img element missing an alt attribute. Use the alt attribute to specify a short text alternative. Details Details',
      );
      expect(text.firstResolvedError).toBe(
        'Fixed The accessibility scanning found an error of the following type: WCAG2AA.Principle2.Guideline2_4.2_4_1.H64.1 Message: Iframe element requires a non-empty title attribute that identifies the frame. Details Details',
      );
      expect(text.secondResolvedError).toBe(
        'The accessibility scanning found an error of the following type: WCAG2AA.Principle3.Guideline3_2.3_2_2.H32.2 Message: This form does not contain a submit button, which creates issues for those who cannot submit the form using the keyboard. Submit buttons are INPUT elements with type attribute &quot;submit&quot; or &quot;image&quot;, or BUTTON elements with type &quot;submit&quot; or omitted/invalid. Details Details',
      );
    });

    it('report list item has a correct link pointing to the error description', () => {
      const links = findAllExtensionListItems().wrappers.map((item) =>
        item.find('a').attributes('href'),
      );

      expect(links).toEqual([
        'https://www.w3.org/TR/WCAG20-TECHS/H64.html',
        'https://www.w3.org/TR/WCAG20-TECHS/H32.html',
        'https://www.w3.org/TR/WCAG20-TECHS/H64.html',
        'https://www.w3.org/TR/WCAG20-TECHS/H30.html',
        'https://www.w3.org/TR/WCAG20-TECHS/H37.html',
        'https://www.w3.org/TR/WCAG20-TECHS/H64.html',
        'https://www.w3.org/TR/WCAG20-TECHS/H32.html',
      ]);
    });
  });
});

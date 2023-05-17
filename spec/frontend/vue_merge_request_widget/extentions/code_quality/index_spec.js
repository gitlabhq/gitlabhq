import MockAdapter from 'axios-mock-adapter';
import { GlBadge } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import { trimText } from 'helpers/text_helper';
import waitForPromises from 'helpers/wait_for_promises';
import axios from '~/lib/utils/axios_utils';
import extensionsContainer from '~/vue_merge_request_widget/components/extensions/container';
import { registerExtension } from '~/vue_merge_request_widget/components/extensions';
import codeQualityExtension from '~/vue_merge_request_widget/extensions/code_quality';
import {
  HTTP_STATUS_INTERNAL_SERVER_ERROR,
  HTTP_STATUS_NO_CONTENT,
  HTTP_STATUS_OK,
} from '~/lib/utils/http_status';
import {
  i18n,
  codeQualityPrefixes,
} from '~/vue_merge_request_widget/extensions/code_quality/constants';
import {
  codeQualityResponseNewErrors,
  codeQualityResponseResolvedErrors,
  codeQualityResponseResolvedAndNewErrors,
  codeQualityResponseNoErrors,
} from './mock_data';

describe('Code Quality extension', () => {
  let wrapper;
  let mock;

  registerExtension(codeQualityExtension);

  const endpoint = '/root/repo/-/merge_requests/4/accessibility_reports.json';

  const mockApi = (statusCode, data) => {
    mock.onGet(endpoint).reply(statusCode, data);
  };

  const findToggleCollapsedButton = () => wrapper.findByTestId('toggle-button');
  const findAllExtensionListItems = () => wrapper.findAllByTestId('extension-list-item');
  const isCollapsable = () => wrapper.findByTestId('toggle-button').exists();
  const getNeutralIcon = () => wrapper.findByTestId('status-neutral-icon').exists();
  const getAlertIcon = () => wrapper.findByTestId('status-alert-icon').exists();
  const getSuccessIcon = () => wrapper.findByTestId('status-success-icon').exists();

  const createComponent = () => {
    wrapper = mountExtended(extensionsContainer, {
      propsData: {
        mr: {
          codeQuality: endpoint,
          blobPath: {
            head_path: 'example/path',
            base_path: 'example/path',
          },
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
      mockApi(HTTP_STATUS_OK, codeQualityResponseNewErrors);

      createComponent();

      expect(wrapper.text()).toBe(i18n.loading);
    });

    it('with a 204 response, continues to display loading state', async () => {
      mockApi(HTTP_STATUS_NO_CONTENT, '');
      createComponent();

      await waitForPromises();

      expect(wrapper.text()).toBe(i18n.loading);
    });

    it('displays failed loading text', async () => {
      mockApi(HTTP_STATUS_INTERNAL_SERVER_ERROR);

      createComponent();

      await waitForPromises();

      expect(wrapper.text()).toBe(i18n.error);
      expect(isCollapsable()).toBe(false);
    });

    it('displays new Errors finding', async () => {
      mockApi(HTTP_STATUS_OK, codeQualityResponseNewErrors);

      createComponent();

      await waitForPromises();
      expect(wrapper.text()).toBe(
        i18n
          .singularCopy(
            i18n.findings(codeQualityResponseNewErrors.new_errors, codeQualityPrefixes.new),
          )
          .replace(/%{strong_start}/g, '')
          .replace(/%{strong_end}/g, ''),
      );
      expect(isCollapsable()).toBe(true);
      expect(getAlertIcon()).toBe(true);
    });

    it('displays resolved Errors finding', async () => {
      mockApi(HTTP_STATUS_OK, codeQualityResponseResolvedErrors);

      createComponent();

      await waitForPromises();
      expect(wrapper.text()).toBe(
        i18n
          .singularCopy(
            i18n.findings(
              codeQualityResponseResolvedErrors.resolved_errors,
              codeQualityPrefixes.fixed,
            ),
          )
          .replace(/%{strong_start}/g, '')
          .replace(/%{strong_end}/g, ''),
      );
      expect(isCollapsable()).toBe(true);
      expect(getSuccessIcon()).toBe(true);
    });

    it('displays quality improvement and degradation', async () => {
      mockApi(HTTP_STATUS_OK, codeQualityResponseResolvedAndNewErrors);

      createComponent();
      await waitForPromises();

      // replacing strong tags because they will not be found in the rendered text
      expect(wrapper.text()).toBe(
        i18n
          .improvementAndDegradationCopy(
            i18n.findings(
              codeQualityResponseResolvedAndNewErrors.resolved_errors,
              codeQualityPrefixes.fixed,
            ),
            i18n.findings(
              codeQualityResponseResolvedAndNewErrors.new_errors,
              codeQualityPrefixes.new,
            ),
          )
          .replace(/%{strong_start}/g, '')
          .replace(/%{strong_end}/g, ''),
      );
      expect(isCollapsable()).toBe(true);
      expect(getAlertIcon()).toBe(true);
    });

    it('displays no detected errors', async () => {
      mockApi(HTTP_STATUS_OK, codeQualityResponseNoErrors);

      createComponent();

      await waitForPromises();

      expect(wrapper.text()).toBe(i18n.noChanges);
      expect(isCollapsable()).toBe(false);
      expect(getNeutralIcon()).toBe(true);
    });
  });

  describe('expanded data', () => {
    beforeEach(async () => {
      mockApi(HTTP_STATUS_OK, codeQualityResponseResolvedAndNewErrors);

      createComponent();

      await waitForPromises();

      findToggleCollapsedButton().trigger('click');

      await waitForPromises();
    });

    it('displays all report list items in viewport', () => {
      expect(findAllExtensionListItems()).toHaveLength(4);
    });

    it('displays report list item formatted', () => {
      const text = {
        newError: trimText(findAllExtensionListItems().at(0).text().replace(/\s+/g, ' ').trim()),
        resolvedError: findAllExtensionListItems().at(2).text().replace(/\s+/g, ' ').trim(),
      };

      expect(text.newError).toContain(
        "Minor - Parsing error: 'return' outside of function in index.js:12",
      );
      expect(text.resolvedError).toContain(
        "Minor - Parsing error: 'return' outside of function Fixed in index.js:12",
      );
    });

    it('displays report list item formatted with check_name', () => {
      const text = {
        newError: trimText(findAllExtensionListItems().at(1).text().replace(/\s+/g, ' ').trim()),
        resolvedError: findAllExtensionListItems().at(3).text().replace(/\s+/g, ' ').trim(),
      };

      expect(text.newError).toContain(
        'Minor - Rubocop/Metrics/ParameterLists - Avoid parameter lists longer than 5 parameters. [12/5] in main.rb:3',
      );
      expect(text.resolvedError).toContain(
        'Minor - Rubocop/Metrics/ParameterLists - Avoid parameter lists longer than 5 parameters. [12/5] Fixed in main.rb:3',
      );
    });

    it('adds fixed indicator (badge) when error is resolved', () => {
      expect(findAllExtensionListItems().at(3).findComponent(GlBadge).exists()).toBe(true);
      expect(findAllExtensionListItems().at(3).findComponent(GlBadge).text()).toEqual(i18n.fixed);
    });

    it('should not add fixed indicator (badge) when error is new', () => {
      expect(findAllExtensionListItems().at(0).findComponent(GlBadge).exists()).toBe(false);
    });
  });
});

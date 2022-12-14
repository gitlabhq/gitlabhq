import MockAdapter from 'axios-mock-adapter';
import { GlBadge } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import { trimText } from 'helpers/text_helper';
import waitForPromises from 'helpers/wait_for_promises';
import axios from '~/lib/utils/axios_utils';
import extensionsContainer from '~/vue_merge_request_widget/components/extensions/container';
import { registerExtension } from '~/vue_merge_request_widget/components/extensions';
import codeQualityExtension from '~/vue_merge_request_widget/extensions/code_quality';
import httpStatusCodes from '~/lib/utils/http_status';
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
    wrapper.destroy();
    mock.restore();
  });

  describe('summary', () => {
    it('displays loading text', () => {
      mockApi(httpStatusCodes.OK, codeQualityResponseNewErrors);

      createComponent();

      expect(wrapper.text()).toBe('Code Quality test metrics results are being parsed');
    });

    it('displays failed loading text', async () => {
      mockApi(httpStatusCodes.INTERNAL_SERVER_ERROR);

      createComponent();

      await waitForPromises();
      expect(wrapper.text()).toBe('Code Quality failed loading results');
    });

    it('displays quality degradation', async () => {
      mockApi(httpStatusCodes.OK, codeQualityResponseNewErrors);

      createComponent();

      await waitForPromises();

      expect(wrapper.text()).toBe('Code Quality degraded on 2 points.');
    });

    it('displays quality improvement', async () => {
      mockApi(httpStatusCodes.OK, codeQualityResponseResolvedErrors);

      createComponent();

      await waitForPromises();

      expect(wrapper.text()).toBe('Code Quality improved on 2 points.');
    });

    it('displays quality improvement and degradation', async () => {
      mockApi(httpStatusCodes.OK, codeQualityResponseResolvedAndNewErrors);

      createComponent();

      await waitForPromises();

      expect(wrapper.text()).toBe('Code Quality improved on 1 point and degraded on 1 point.');
    });

    it('displays no detected errors', async () => {
      mockApi(httpStatusCodes.OK, codeQualityResponseNoErrors);

      createComponent();

      await waitForPromises();

      expect(wrapper.text()).toBe('No changes to Code Quality.');
    });
  });

  describe('expanded data', () => {
    beforeEach(async () => {
      mockApi(httpStatusCodes.OK, codeQualityResponseResolvedAndNewErrors);

      createComponent();

      await waitForPromises();

      findToggleCollapsedButton().trigger('click');

      await waitForPromises();
    });

    it('displays all report list items in viewport', async () => {
      expect(findAllExtensionListItems()).toHaveLength(2);
    });

    it('displays report list item formatted', () => {
      const text = {
        newError: trimText(findAllExtensionListItems().at(0).text().replace(/\s+/g, ' ').trim()),
        resolvedError: findAllExtensionListItems().at(1).text().replace(/\s+/g, ' ').trim(),
      };

      expect(text.newError).toContain(
        "Minor - Parsing error: 'return' outside of function in index.js:12",
      );
      expect(text.resolvedError).toContain(
        "Minor - Parsing error: 'return' outside of function Fixed in index.js:12",
      );
    });

    it('adds fixed indicator (badge) when error is resolved', () => {
      expect(findAllExtensionListItems().at(1).findComponent(GlBadge).exists()).toBe(true);
      expect(findAllExtensionListItems().at(1).findComponent(GlBadge).text()).toEqual('Fixed');
    });

    it('should not add fixed indicator (badge) when error is new', () => {
      expect(findAllExtensionListItems().at(0).findComponent(GlBadge).exists()).toBe(false);
    });
  });
});

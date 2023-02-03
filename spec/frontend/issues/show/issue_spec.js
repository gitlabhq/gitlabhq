import MockAdapter from 'axios-mock-adapter';
import waitForPromises from 'helpers/wait_for_promises';
import { initIssueApp } from '~/issues/show';
import * as parseData from '~/issues/show/utils/parse_data';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_OK } from '~/lib/utils/http_status';
import createStore from '~/notes/stores';
import { appProps } from './mock_data/mock_data';

const mock = new MockAdapter(axios);
mock.onGet().reply(HTTP_STATUS_OK);

jest.mock('~/lib/utils/poll');

const setupHTML = (initialData) => {
  document.body.innerHTML = `<div id="js-issuable-app"></div>`;
  document.getElementById('js-issuable-app').dataset.initial = JSON.stringify(initialData);
};

describe('Issue show index', () => {
  describe('initIssueApp', () => {
    // https://gitlab.com/gitlab-org/gitlab/-/issues/390368
    // eslint-disable-next-line jest/no-disabled-tests
    it.skip('should initialize app with no potential XSS attack', async () => {
      const alertSpy = jest.spyOn(window, 'alert').mockImplementation(() => {});
      const parseDataSpy = jest.spyOn(parseData, 'parseIssuableData');

      setupHTML({
        ...appProps,
        initialDescriptionHtml: '<svg onload=window.alert(1)>',
      });

      const initialDataEl = document.getElementById('js-issuable-app');
      const issuableData = parseData.parseIssuableData(initialDataEl);
      initIssueApp(issuableData, createStore());

      await waitForPromises();

      expect(parseDataSpy).toHaveBeenCalled();
      expect(alertSpy).not.toHaveBeenCalled();
    });
  });
});

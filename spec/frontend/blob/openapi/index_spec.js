import axios from 'axios';
import MockAdapter from 'axios-mock-adapter';
import { TEST_HOST } from 'helpers/test_constants';
import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import renderOpenApi from '~/blob/openapi';
import { HTTP_STATUS_OK } from '~/lib/utils/http_status';
import setWindowLocation from 'helpers/set_window_location_helper';

describe('OpenAPI blob viewer', () => {
  const id = 'js-openapi-viewer';
  const mockEndpoint = 'some/endpoint';
  let mock;

  beforeEach(() => {
    setHTMLFixture(`<div id="${id}" data-endpoint="${mockEndpoint}"></div>`);
    mock = new MockAdapter(axios).onGet().reply(HTTP_STATUS_OK);
  });

  afterEach(() => {
    resetHTMLFixture();
    mock.restore();
  });

  describe('without config options', () => {
    beforeEach(async () => {
      await renderOpenApi();
    });

    it('initializes SwaggerUI without config options', () => {
      expect(document.body.innerHTML).toContain(
        `<iframe src="${TEST_HOST}/-/sandbox/swagger" sandbox="allow-scripts allow-popups allow-forms" frameborder="0" width="100%" height="1000"></iframe>`,
      );
    });
  });

  describe('with config options', () => {
    beforeEach(async () => {
      setWindowLocation('?displayOperationId=true');
      await renderOpenApi();
    });

    it('initializes SwaggerUI with the correct config options', () => {
      expect(document.body.innerHTML).toContain(
        `<iframe src="${TEST_HOST}/-/sandbox/swagger?displayOperationId=true" sandbox="allow-scripts allow-popups allow-forms" frameborder="0" width="100%" height="1000"></iframe>`,
      );
    });
  });
});

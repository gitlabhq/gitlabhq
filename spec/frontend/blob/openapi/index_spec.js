import axios from 'axios';
import MockAdapter from 'axios-mock-adapter';
import { TEST_HOST } from 'helpers/test_constants';
import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import renderOpenApi from '~/blob/openapi';
import { HTTP_STATUS_OK } from '~/lib/utils/http_status';

describe('OpenAPI blob viewer', () => {
  const id = 'js-openapi-viewer';
  const mockEndpoint = 'some/endpoint';
  let mock;

  beforeEach(async () => {
    setHTMLFixture(`<div id="${id}" data-endpoint="${mockEndpoint}"></div>`);
    mock = new MockAdapter(axios).onGet().reply(HTTP_STATUS_OK);
    await renderOpenApi();
  });

  afterEach(() => {
    resetHTMLFixture();
    mock.restore();
  });

  it('initializes SwaggerUI with the correct configuration', () => {
    expect(document.body.innerHTML).toContain(
      `<iframe src="${TEST_HOST}/-/sandbox/swagger" sandbox="allow-scripts allow-popups allow-forms" frameborder="0" width="100%" height="1000"></iframe>`,
    );
  });
});

import SwaggerClient from 'swagger-client';
import { TEST_HOST } from 'helpers/test_constants';
import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import renderOpenApi from '~/blob/openapi';
import setWindowLocation from 'helpers/set_window_location_helper';

describe('OpenAPI blob viewer', () => {
  const id = 'js-openapi-viewer';
  const mockEndpoint = 'some/endpoint';

  beforeEach(() => {
    jest.spyOn(SwaggerClient, 'resolve').mockReturnValue(Promise.resolve({ spec: 'some spec' }));
    setHTMLFixture(`<div id="${id}" data-endpoint="${mockEndpoint}"></div>`);
  });

  afterEach(() => {
    resetHTMLFixture();
  });

  it('bundles the spec file', async () => {
    await renderOpenApi();
    expect(SwaggerClient.resolve).toHaveBeenCalledWith({ url: mockEndpoint });
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

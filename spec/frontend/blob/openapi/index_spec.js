import { SwaggerUIBundle } from 'swagger-ui-dist';
import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import renderOpenApi from '~/blob/openapi';

jest.mock('swagger-ui-dist');

describe('OpenAPI blob viewer', () => {
  const id = 'js-openapi-viewer';
  const mockEndpoint = 'some/endpoint';

  beforeEach(() => {
    setHTMLFixture(`<div id="${id}" data-endpoint="${mockEndpoint}"></div>`);
    renderOpenApi();
  });

  afterEach(() => {
    resetHTMLFixture();
  });

  it('initializes SwaggerUI with the correct configuration', () => {
    expect(SwaggerUIBundle).toHaveBeenCalledWith({
      url: mockEndpoint,
      dom_id: `#${id}`,
      deepLinking: true,
      displayOperationId: true,
    });
  });
});

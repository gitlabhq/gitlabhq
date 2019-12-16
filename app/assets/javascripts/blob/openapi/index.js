import { SwaggerUIBundle } from 'swagger-ui-dist';
import flash from '~/flash';
import { __ } from '~/locale';

export default () => {
  const el = document.getElementById('js-openapi-viewer');

  Promise.all([import(/* webpackChunkName: 'openapi' */ 'swagger-ui-dist/swagger-ui.css')])
    .then(() => {
      SwaggerUIBundle({
        url: el.dataset.endpoint,
        dom_id: '#js-openapi-viewer',
      });
    })
    .catch(error => {
      flash(__('Something went wrong while initializing the OpenAPI viewer'));
      throw error;
    });
};

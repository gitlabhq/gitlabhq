import { SwaggerUIBundle } from 'swagger-ui-dist';
import createFlash from '~/flash';
import { removeParams, updateHistory } from '~/lib/utils/url_utility';
import { __ } from '~/locale';

export default () => {
  const el = document.getElementById('js-openapi-viewer');

  Promise.all([import(/* webpackChunkName: 'openapi' */ 'swagger-ui-dist/swagger-ui.css')])
    .then(() => {
      // Temporary fix to prevent an XSS attack due to "useUnsafeMarkdown"
      // Once we upgrade Swagger to "4.0.0", we can safely remove this as it will be deprecated
      // Follow-up issue: https://gitlab.com/gitlab-org/gitlab/-/issues/339696
      updateHistory({ url: removeParams(['useUnsafeMarkdown']), replace: true });
      SwaggerUIBundle({
        url: el.dataset.endpoint,
        dom_id: '#js-openapi-viewer',
        useUnsafeMarkdown: false,
      });
    })
    .catch((error) => {
      createFlash({
        message: __('Something went wrong while initializing the OpenAPI viewer'),
      });
      throw error;
    });
};

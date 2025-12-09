import { SwaggerUIBundle } from 'swagger-ui-dist';
import { safeLoad } from 'js-yaml';
import { isObject } from '~/lib/utils/type_utility';
import { getParameterByName } from '~/lib/utils/url_utility';
import { resetServiceWorkersPublicPath } from '~/lib/utils/webpack';

const resetWebpackPublicPath = (relativeRootPath) => {
  if (!relativeRootPath || !relativeRootPath.startsWith('/') || relativeRootPath.startsWith('//')) {
    return;
  }

  window.gon = { relative_url_root: relativeRootPath };
  resetServiceWorkersPublicPath();
};

const renderSwaggerUI = (spec, relativeRootPath) => {
  /* SwaggerUIBundle accepts openapi definition
   * in only JSON format, so we convert the YAML
   * config to JSON if it's not JSON value
   */
  let parsedSpec = spec;
  if (!isObject(parsedSpec)) {
    parsedSpec = safeLoad(parsedSpec, { json: true });
  }

  resetWebpackPublicPath(relativeRootPath);

  Promise.all([import(/* webpackChunkName: 'openapi' */ 'swagger-ui-dist/swagger-ui.css')])
    .then(() => {
      SwaggerUIBundle({
        spec: parsedSpec,
        dom_id: '#swagger-ui',
        deepLinking: true,
        displayOperationId: Boolean(getParameterByName('displayOperationId')),
      });
    })
    .catch((error) => {
      throw error;
    });
};

const addInitHook = () => {
  window.addEventListener(
    'message',
    (event) => {
      if (event.origin !== window.location.origin) {
        return;
      }

      let message;

      try {
        message = JSON.parse(event.data);
      } catch (e) {
        return;
      }

      if (message.type !== 'swagger-init' || !message.spec) {
        return;
      }

      const { relativeRootPath } = message;
      renderSwaggerUI(message.spec, relativeRootPath);
    },
    false,
  );
};

addInitHook();
export default {};

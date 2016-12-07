/* global Vue, VueResource, gl */
/* eslint-disable no-bitwise, no-plusplus*/

/*= require vue_common_component/commit */

//= require vue-resource

//= require ./interceptor.js.es6
//= require ./status.js.es6
//= require ./store.js.es6
//= require ./pipeline_url.js.es6
//= require ./pipeline_head.js.es6
//= require ./stage.js.es6
//= require ./stages.js.es6
//= require ./pipeline_actions.js.es6
//= require ./time_ago.js.es6
//= require ./pipelines.js.es6

(() => {
  const project = document.querySelector('.pipelines');
  const entry = document.querySelector('.vue-pipelines-index');

  Vue.use(VueResource);

  if (entry) {
    return new Vue({
      el: entry,
      data: {
        scope: project.dataset.url,
        store: new gl.PipelineStore(),
      },
      components: {
        'vue-pipelines': gl.VuePipelines,
      },
      template: `
        <div>
          <vue-pipelines
            :scope='scope'
            :store='store'
          >
          </vue-pipelines>
        </div>
      `,
    });
  }

  return null;
})();

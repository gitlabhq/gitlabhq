/* global Vue, VueResource, gl */
window.Vue = require('vue');
window.Vue.use(require('vue-resource'));
require('../vue_common_component/commit');
require('../vue_pagination/index');
require('../boards/vue_resource_interceptor');
require('./status');
require('./store');
require('./pipeline_url');
require('./stage');
require('./stages');
require('./pipeline_actions');
require('./time_ago');
require('./pipelines');

(() => {
  const project = document.querySelector('.pipelines');
  const entry = document.querySelector('.vue-pipelines-index');
  const svgs = document.querySelector('.pipeline-svgs');

  if (!entry) return null;
  return new Vue({
    el: entry,
    data: {
      scope: project.dataset.url,
      store: new gl.PipelineStore(),
      svgs: svgs.dataset,
    },
    components: {
      'vue-pipelines': gl.VuePipelines,
    },
    template: `
      <vue-pipelines
        :scope='scope'
        :store='store'
        :svgs='svgs'
      >
      </vue-pipelines>
    `,
  });
})();

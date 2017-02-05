/* eslint-disable no-param-reassign */
/* global Vue, VueResource, gl */
window.Vue = require('vue');
window.Vue.use(require('vue-resource'));
require('../vue_shared/vue_resource_interceptor');
require('./pipelines');

$(() => {
  return new Vue({
    el: document.querySelector('.vue-pipelines-index'),

    data() {
      const project = document.querySelector('.pipelines');
      const svgs = document.querySelector('.pipeline-svgs').dataset;

      // Transform svgs DOMStringMap to a plain Object.
      const svgsObject = Object.keys(svgs).reduce((acc, element) => {
        acc[element] = svgs[element];
        return acc;
      }, {});

      return {
        scope: project.dataset.url,
        store: new gl.PipelineStore(),
        svgs: svgsObject,
      };
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
});

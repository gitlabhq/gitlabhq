/* eslint-disable no-param-reassign */
/* global Vue, VueResource, gl */
window.Vue = require('vue');
window.Vue.use(require('vue-resource'));
require('../lib/utils/common_utils');
require('../vue_shared/vue_resource_interceptor');
require('./pipelines');

$(() => new Vue({
  el: document.querySelector('.vue-pipelines-index'),

  data() {
    const project = document.querySelector('.pipelines');

    return {
      scope: project.dataset.url,
      store: new gl.PipelineStore(),
    };
  },
  components: {
    'vue-pipelines': gl.VuePipelines,
  },
  template: `
    <vue-pipelines
      :scope="scope"
      :store="store">
    </vue-pipelines>
  `,
}));

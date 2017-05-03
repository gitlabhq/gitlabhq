/* global Vue, VueResource, gl */
/*= require vue_common_component/commit */
/*= require vue_pagination/index */
/*= require vue-resource
/*= require boards/vue_resource_interceptor */
/*= require ./status.js.es6 */
/*= require ./store.js.es6 */
/*= require ./pipeline_url.js.es6 */
/*= require ./stage.js.es6 */
/*= require ./stages.js.es6 */
/*= require ./pipeline_actions.js.es6 */
/*= require ./time_ago.js.es6 */
/*= require ./pipelines.js.es6 */

(() => {
  const project = document.querySelector('.pipelines');
  const entry = document.querySelector('.vue-pipelines-index');
  const svgs = document.querySelector('.pipeline-svgs');

  Vue.use(VueResource);

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

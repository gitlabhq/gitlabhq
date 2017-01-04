/* global Vue, VueResource, Flash */
/* eslint-disable no-underscore-dangle */

/*= require vue */
/*= require vue-resource */
/*= require boards/vue_resource_interceptor */

/*= require vue_realtime_listener/index */
//= require ./issue_title

(() => {
  Vue.use(VueResource);

  Vue.activeResources = 0;

  const token = document.querySelector('meta[name="csrf-token"]');
  if (token) Vue.http.headers.common['X-CSRF-token'] = token.content;

  const vueData = document.querySelector('.vue-data').dataset;
  const notUser = vueData.user;

  const vm = new Vue({
    el: '.issue-title-vue',
    components: {
      'vue-title': gl.VueIssueTitle,
    },
    data() {
      return {
        initialTitle: vueData.initialTitle,
        endpoint: vueData.endpoint,
        initialTitleDigest: vueData.initialTitleDigest,
        notUser,
      };
    },
    template: `
      <div>
        <vue-title
          :initialTitle='initialTitle'
          :endpoint='endpoint'
          :notUser='notUser'
          :initialTitleDigest='initialTitleDigest'
        >
        </vue-title>
      </div>
    `,
  });

  if (notUser === 'false') {
    const titleComp = vm.$children
      .filter(e => e.$options._componentTag === 'vue-title')[0];

    const startTitleFetch = () => titleComp.fetch();
    const removeIntervalLoops = () => titleComp.clear();
    const startIntervalLoops = () => startTitleFetch();

    gl.VueRealtimeListener(removeIntervalLoops, startIntervalLoops);
  }
})(window.gl || (window.gl = {}));

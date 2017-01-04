/*= require vue */
/*= require vue-resource */

/*= require vue_realtime_listener/index */
//= require ./issue_title

/* global Vue, VueResource, Flash */
/* eslint-disable no-underscore-dangle */

(() => {
  Vue.use(VueResource);

  /**
    not using vue_resource_interceptor because of the nested call to render html
    this requires a bit more custom logic
    specifically the 'if/else' in the 'setInterval' inside the 'fetch' method
  */
  Vue.activeResources = 0;

  const token = document.querySelector('meta[name="csrf-token"]');
  if (token) Vue.http.headers.post['X-CSRF-token'] = token.content;

  const vueData = document.querySelector('.vue-data').dataset;
  const isNotUser = vueData.user;

  let user;

  if (isNotUser === 'true') {
    user = false;
  } else {
    user = true;
  }

  const vm = new Vue({
    el: '.issue-title-vue',
    components: {
      'vue-title': gl.VueIssueTitle,
    },
    data() {
      return {
        rubyTitle: vueData.rubyTitle,
        endpoint: vueData.endpoint,
        projectPath: vueData.projectPath,
        rubyDiffTitle: vueData.rubyDiffTitle,
        user,
        token,
      };
    },
    template: `
      <div>
        <vue-title
          :rubyTitle='rubyTitle'
          :endpoint='endpoint'
          :projectPath='projectPath'
          :rubyDiffTitle='rubyDiffTitle'
          :user='user'
        >
        </vue-title>
      </div>
    `,
  });

  if (user) {
    const titleComp = vm.$children
      .filter(e => e.$options._componentTag === 'vue-title')[0];

    const startTitleFetch = () => titleComp.fetch();
    const removeIntervalLoops = () => titleComp.clear();
    const startIntervalLoops = () => startTitleFetch();

    gl.VueRealtimeListener(removeIntervalLoops, startIntervalLoops);
  }
})(window.gl || (window.gl = {}));

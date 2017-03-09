/* global Flash */
/* eslint-disable no-underscore-dangle */

const Vue = require('vue');
Vue.use(require('vue-resource'));
require('../vue_shared/vue_resource_interceptor');
const VueRealtimeListener = require('../vue_realtime_listener');
const IssueTitle = require('./issue_title');

const token = document.querySelector('meta[name="csrf-token"]');
if (token) Vue.http.headers.common['X-CSRF-token'] = token.content;

const vueData = document.querySelector('.vue-data').dataset;
const notUser = vueData.user;

const vueOptions = () => ({
  el: '.issue-title-vue',
  components: {
    IssueTitle,
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
      <IssueTitle
        :initialTitle='initialTitle'
        :endpoint='endpoint'
        :notUser='notUser'
        :initialTitleDigest='initialTitleDigest'
      />
    </div>
  `,
});

(() => {
  const vm = new Vue(vueOptions);

  if (notUser === 'false') {
    const titleComp = vm.$children
      .filter(e => e.$options._componentTag === 'vue-title')[0];

    const startTitleFetch = () => titleComp.fetch();
    const removeIntervalLoops = () => titleComp.clear();
    const startIntervalLoops = () => startTitleFetch();

    VueRealtimeListener(removeIntervalLoops, startIntervalLoops);
  }
})();

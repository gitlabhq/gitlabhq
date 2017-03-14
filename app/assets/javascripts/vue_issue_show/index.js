/* global Flash */
/* eslint-disable no-underscore-dangle */

const Vue = require('vue');
Vue.use(require('vue-resource'));
require('../vue_shared/vue_resource_interceptor');
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
  Vue.activeResources = 0;
  const vm = new Vue(vueOptions());
  (() => vm)();
})();

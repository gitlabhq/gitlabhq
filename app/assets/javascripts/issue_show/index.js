import Vue from 'vue';
import IssueTitle from './issue_title.vue';
import '../vue_shared/vue_resource_interceptor';

(() => {
  const issueTitleData = document.querySelector('.issue-title-data').dataset;
  const { initialTitle, endpoint } = issueTitleData;

  const vm = new Vue({
    el: '.issue-title-entrypoint',
    render: createElement => createElement(IssueTitle, {
      props: {
        initialTitle,
        endpoint,
      },
    }),
  });

  return vm;
})();

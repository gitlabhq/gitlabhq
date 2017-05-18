import Vue from 'vue';
import IssueTitle from './issue_title_description.vue';
import '../vue_shared/vue_resource_interceptor';

(() => {
  const issueTitleData = document.querySelector('.issue-title-data').dataset;
  const { canUpdateTasksClass, endpoint, isEdited } = issueTitleData;

  const vm = new Vue({
    el: '.issue-title-entrypoint',
    render: createElement => createElement(IssueTitle, {
      props: {
        canUpdateTasksClass,
        endpoint,
        isEdited,
      },
    }),
  });

  return vm;
})();

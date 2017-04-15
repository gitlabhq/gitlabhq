import Vue from 'vue';
import IssueTitle from './issue_title';
import '../vue_shared/vue_resource_interceptor';

const vueOptions = () => ({
  el: '.issue-title-entrypoint',
  components: {
    IssueTitle,
  },
  data() {
    const issueTitleData = document.querySelector('.issue-title-data').dataset;

    return {
      initialTitle: issueTitleData.initialTitle,
      endpoint: issueTitleData.endpoint,
    };
  },
  template: `
    <IssueTitle
      :initialTitle="initialTitle"
      :endpoint="endpoint"
    />
  `,
});

(() => new Vue(vueOptions()))();

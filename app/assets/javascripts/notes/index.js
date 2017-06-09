import Vue from 'vue';
import IssueNotes from './components/issue_notes.vue';

document.addEventListener('DOMContentLoaded', () => new Vue({
  el: '#js-notes',
  components: { IssueNotes },
  template: `
    <issue-notes />
  `,
}));

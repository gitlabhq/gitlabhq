import Vue from 'vue';
import issueNotes from './components/issue_notes.vue';
import '../vue_shared/vue_resource_interceptor';

document.addEventListener('DOMContentLoaded', () => {
  const vm = new Vue({
    el: '#js-notes',
    components: {
      issueNotes,
    },
    template: `
      <issue-notes ref="notes" />
    `,
  });

  window.issueNotes = {
    refresh() {
      vm.$refs.notes.$store.dispatch('poll');
    },
  };
});

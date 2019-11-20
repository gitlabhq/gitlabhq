import Vue from 'vue';
import store from './store';
import ErrorDetails from './components/error_details.vue';

export default () => {
  // eslint-disable-next-line no-new
  new Vue({
    el: '#js-error_details',
    components: {
      ErrorDetails,
    },
    store,
    render(createElement) {
      const domEl = document.querySelector(this.$options.el);
      const { issueDetailsPath, issueStackTracePath, issueProjectPath } = domEl.dataset;

      return createElement('error-details', {
        props: {
          issueDetailsPath,
          issueStackTracePath,
          issueProjectPath,
        },
      });
    },
  });
};

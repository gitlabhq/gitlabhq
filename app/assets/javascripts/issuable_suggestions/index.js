import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import App from './components/app.vue';

Vue.use(VueApollo);

export default function() {
  const el = document.getElementById('js-suggestions');
  const issueTitle = document.getElementById('issue_title');
  const { projectPath } = el.dataset;
  const apolloProvider = new VueApollo({
    defaultClient: createDefaultClient(),
  });

  return new Vue({
    el,
    apolloProvider,
    data() {
      return {
        search: issueTitle.value,
      };
    },
    mounted() {
      issueTitle.addEventListener('input', () => {
        this.search = issueTitle.value;
      });
    },
    render(h) {
      return h(App, {
        props: {
          projectPath,
          search: this.search,
        },
      });
    },
  });
}

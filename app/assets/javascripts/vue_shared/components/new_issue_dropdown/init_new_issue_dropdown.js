import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import NewIssueDropdown from './new_issue_dropdown.vue';

Vue.use(VueApollo);

const apolloProvider = new VueApollo({
  defaultClient: createDefaultClient(),
});

export const initNewIssueDropdown = () => {
  const el = document.querySelector('.js-new-issue-dropdown');

  if (!el) {
    return false;
  }

  return new Vue({
    el,
    apolloProvider,
    render(createElement) {
      return createElement(NewIssueDropdown, {
        props: {
          withLocalStorage: true,
        },
      });
    },
  });
};

import Vue from 'vue';
import VueApollo from 'vue-apollo';
import createDefaultClient from '~/lib/graphql';
import TitleSuggestions from './components/title_suggestions.vue';
import TypePopover from './components/type_popover.vue';

export function initTitleSuggestions() {
  const el = document.getElementById('js-suggestions');
  const issueTitle = document.getElementById('issue_title');

  if (!el) {
    return undefined;
  }

  Vue.use(VueApollo);

  const apolloProvider = new VueApollo({
    defaultClient: createDefaultClient(),
  });

  return new Vue({
    el,
    name: 'TitleSuggestionsRoot',
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
    render(createElement) {
      return createElement(TitleSuggestions, {
        props: {
          projectPath: el.dataset.projectPath,
          search: this.search,
        },
      });
    },
  });
}

export function initTypePopover() {
  const el = document.getElementById('js-type-popover');

  if (!el) {
    return undefined;
  }

  return new Vue({
    el,
    name: 'TypePopoverRoot',
    render: (createElement) => createElement(TypePopover),
  });
}

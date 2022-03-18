import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { __ } from '~/locale';
import createDefaultClient from '~/lib/graphql';
import NavigationPopover from './components/navigation_popover.vue';

Vue.use(VueApollo);

const apolloProvider = new VueApollo({
  defaultClient: createDefaultClient(),
});

export const initTopNavPopover = () => {
  const el = document.getElementById('js-need-attention-nav-onboarding');

  if (!el) return;

  // eslint-disable-next-line no-new
  new Vue({
    el,
    apolloProvider,
    provide: {
      observerElSelector: '.user-counter.dropdown',
      observerElToggledClass: 'show',
      message: [
        __(
          '%{strongStart}Need your attention%{strongEnd} are the merge requests that need your help to move forward, as an assignee or reviewer.',
        ),
      ],
      featureName: 'attention_requests_top_nav',
      popoverTarget: '#js-need-attention-nav',
    },
    render(h) {
      return h(NavigationPopover);
    },
  });
};

export const initSideNavPopover = () => {
  const el = document.getElementById('js-need-attention-sidebar-onboarding');

  if (!el) return;

  // eslint-disable-next-line no-new
  new Vue({
    el,
    apolloProvider,
    provide: {
      observerElSelector: '.js-right-sidebar',
      observerElToggledClass: 'right-sidebar-expanded',
      message: [
        __(
          'To ask someone to look at a merge request, select %{strongStart}Request attention%{strongEnd}. Select again to remove the request.',
        ),
        __(
          'Some actions remove attention requests, like a reviewer approving or anyone merging the merge request.',
        ),
      ],
      featureName: 'attention_requests_side_nav',
      popoverTarget: '.js-attention-request-toggle',
      showAttentionIcon: true,
      delay: 500,
      popoverCssClass: 'attention-request-sidebar-popover',
    },
    render(h) {
      return h(NavigationPopover);
    },
  });
};

export default () => {
  initTopNavPopover();
};

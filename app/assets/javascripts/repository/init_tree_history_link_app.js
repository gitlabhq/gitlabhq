import Vue from 'vue';
import VueRouter from 'vue-router';
import { GlButton } from '@gitlab/ui';
import { __ } from '~/locale';
import { generateHistoryUrl } from '~/repository/utils/url_utility';
import { HISTORY_BUTTON_CLICK } from '~/tracking/constants';

export default function initTreeHistoryLinkApp() {
  const treeHistoryLinkEl = document.getElementById('js-commit-history-link');
  if (!treeHistoryLinkEl) return null;

  const { historyLink } = treeHistoryLinkEl.dataset;

  return new Vue({
    el: treeHistoryLinkEl,
    name: 'BlobTreeHistoryLink',
    router: new VueRouter({ mode: 'history' }),
    render(h) {
      const url = generateHistoryUrl(
        historyLink,
        this.$route.params.path,
        this.$route.meta.refType || this.$route.query.ref_type,
      );
      return h(
        GlButton,
        {
          attrs: {
            href: url.href,
            'data-event-tracking': HISTORY_BUTTON_CLICK,
          },
        },
        [__('History')],
      );
    },
  });
}

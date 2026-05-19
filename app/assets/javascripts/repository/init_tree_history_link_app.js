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
    computed: {
      currentPath() {
        return this.$route.params.path;
      },
      refType() {
        return this.$route.meta.refType || this.$route.query.ref_type;
      },
      historyUrl() {
        return generateHistoryUrl(historyLink, this.currentPath, this.refType);
      },
    },
    render(h) {
      return h(
        GlButton,
        {
          attrs: {
            href: this.historyUrl.href,
            'data-event-tracking': HISTORY_BUTTON_CLICK,
          },
        },
        [__('History')],
      );
    },
  });
}

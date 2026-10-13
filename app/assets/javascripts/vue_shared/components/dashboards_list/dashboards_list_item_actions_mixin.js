import { GlToastMixin } from '@gitlab/ui';
import { __, s__ } from '~/locale';
import { relativePathToAbsolute, getBaseURL } from '~/lib/utils/url_utility';

// Open and copy-link behavior shared between the CE and EE
// dashboards_list_item_actions components, so the two stay in sync;
// EE adds only the delete item on top.
export default {
  mixins: [GlToastMixin],
  props: {
    dashboardUrl: {
      type: String,
      required: false,
      default: '',
    },
  },
  computed: {
    // The copied link must work outside the app, so expand the relative
    // dashboard path to an absolute URL.
    absoluteDashboardUrl() {
      return relativePathToAbsolute(this.dashboardUrl, getBaseURL());
    },
    // An href makes the dropdown item render as a real anchor, keeping
    // new-tab and copy-link semantics without a click handler.
    openDashboardItem() {
      return { text: s__('AnalyticsDashboards|Open dashboard'), href: this.dashboardUrl };
    },
  },
  methods: {
    handleCopyLinkAction() {
      this.$toast.show(__('Link copied to clipboard.'));
    },
  },
  copyLinkItem: { text: __('Copy link') },
};

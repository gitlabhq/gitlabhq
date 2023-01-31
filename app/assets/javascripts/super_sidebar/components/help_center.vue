<script>
import { GlDisclosureDropdown } from '@gitlab/ui';
import { helpPagePath } from '~/helpers/help_page_helper';
import { PROMO_URL } from 'jh_else_ce/lib/utils/url_utility';
import { __ } from '~/locale';

export default {
  components: {
    GlDisclosureDropdown,
  },
  i18n: {
    help: __('Help'),
    support: __('Support'),
    docs: __('GitLab documentation'),
    plans: __('Compare GitLab plans'),
    forum: __('Community forum'),
    contribute: __('Contribute to GitLab'),
    feedback: __('Provide feedback'),
    shortcuts: __('Keyboard shortcuts'),
    whatsnew: __("What's new"),
  },
  props: {
    sidebarData: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      items: [
        {
          items: [
            { text: this.$options.i18n.help, href: helpPagePath() },
            { text: this.$options.i18n.support, href: this.sidebarData.support_path },
            { text: this.$options.i18n.docs, href: 'https://docs.gitlab.com' },
            { text: this.$options.i18n.plans, href: `${PROMO_URL}/pricing` },
            { text: this.$options.i18n.forum, href: 'https://forum.gitlab.com/' },
            {
              text: this.$options.i18n.contribute,
              href: helpPagePath('', { anchor: 'contributing-to-gitlab' }),
            },
            { text: this.$options.i18n.feedback, href: 'https://about.gitlab.com/submit-feedback' },
          ],
        },
        {
          items: [
            { text: this.$options.i18n.shortcuts, action: this.showKeyboardShortcuts },
            this.sidebarData.display_whats_new && {
              text: this.$options.i18n.whatsnew,
              action: this.showWhatsNew,
            },
          ].filter(Boolean),
        },
      ],
    };
  },
  methods: {
    showKeyboardShortcuts() {
      this.$refs.dropdown.close();
      window?.toggleShortcutsHelp();
    },
    async showWhatsNew() {
      this.$refs.dropdown.close();
      if (!this.toggleWhatsNewDrawer) {
        const appEl = document.getElementById('whats-new-app');
        const { default: toggleWhatsNewDrawer } = await import(
          /* webpackChunkName: 'whatsNewApp' */ '~/whats_new'
        );
        this.toggleWhatsNewDrawer = toggleWhatsNewDrawer;
        this.toggleWhatsNewDrawer(appEl);
      } else {
        this.toggleWhatsNewDrawer();
      }
    },
  },
};
</script>

<template>
  <gl-disclosure-dropdown
    ref="dropdown"
    icon="question-o"
    :items="items"
    :toggle-text="$options.i18n.help"
    category="tertiary"
    no-caret
  />
</template>

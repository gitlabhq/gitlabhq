<script>
import { GlBadge, GlButton, GlDisclosureDropdown, GlDisclosureDropdownGroup } from '@gitlab/ui';
import GitlabVersionCheckBadge from '~/gitlab_version_check/components/gitlab_version_check_badge.vue';
import { helpPagePath } from '~/helpers/help_page_helper';
import { PROMO_URL } from 'jh_else_ce/lib/utils/url_utility';
import { __ } from '~/locale';
import { STORAGE_KEY } from '~/whats_new/utils/notification';

export default {
  components: {
    GlBadge,
    GlButton,
    GlDisclosureDropdown,
    GlDisclosureDropdownGroup,
    GitlabVersionCheckBadge,
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
    version: __('Your GitLab version'),
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
      showWhatsNewNotification: this.shouldShowWhatsNewNotification(),
    };
  },
  computed: {
    itemGroups() {
      return {
        versionCheck: {
          items: [
            {
              text: this.$options.i18n.version,
              href: helpPagePath('update/index'),
              version: `${this.sidebarData.gitlab_version.major}.${this.sidebarData.gitlab_version.minor}`,
            },
          ],
        },
        helpLinks: {
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
        helpActions: {
          items: [
            {
              text: this.$options.i18n.shortcuts,
              action: this.showKeyboardShortcuts,
              shortcut: '?',
            },
            this.sidebarData.display_whats_new && {
              text: this.$options.i18n.whatsnew,
              action: this.showWhatsNew,
              count:
                this.showWhatsNewNotification &&
                this.sidebarData.whats_new_most_recent_release_items_count,
            },
          ].filter(Boolean),
        },
      };
    },
    updateSeverity() {
      return this.sidebarData.gitlab_version_check?.severity;
    },
  },
  methods: {
    shouldShowWhatsNewNotification() {
      if (
        !this.sidebarData.display_whats_new ||
        localStorage.getItem(STORAGE_KEY) === this.sidebarData.whats_new_version_digest
      ) {
        return false;
      }
      return true;
    },

    handleAction({ action }) {
      if (action) {
        action();
      }
    },

    showKeyboardShortcuts() {
      this.$refs.dropdown.close();
      window?.toggleShortcutsHelp();
    },

    async showWhatsNew() {
      this.$refs.dropdown.close();
      this.showWhatsNewNotification = false;

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
  <gl-disclosure-dropdown ref="dropdown">
    <template #toggle>
      <gl-button category="tertiary" icon="question-o" class="btn-with-notification">
        <span v-if="showWhatsNewNotification" class="notification"></span>
        {{ $options.i18n.help }}
      </gl-button>
    </template>

    <gl-disclosure-dropdown-group
      v-if="sidebarData.show_version_check"
      :group="itemGroups.versionCheck"
    >
      <template #list-item="{ item }">
        <a
          :href="item.href"
          tabindex="-1"
          class="gl-display-flex gl-flex-direction-column gl-line-height-24 gl-text-gray-900 gl-hover-text-gray-900 gl-hover-text-decoration-none"
        >
          <span class="gl-font-sm gl-font-weight-bold">
            {{ item.text }}
            <gl-emoji data-name="rocket" />
          </span>
          <span>
            <span class="gl-mr-2">{{ item.version }}</span>
            <gitlab-version-check-badge v-if="updateSeverity" :status="updateSeverity" size="sm" />
          </span>
        </a>
      </template>
    </gl-disclosure-dropdown-group>

    <gl-disclosure-dropdown-group
      :group="itemGroups.helpLinks"
      :bordered="sidebarData.show_version_check"
    />

    <gl-disclosure-dropdown-group :group="itemGroups.helpActions" bordered @action="handleAction">
      <template #list-item="{ item }">
        <button
          tabindex="-1"
          class="gl-bg-transparent gl-w-full gl-border-none gl-display-flex gl-justify-content-space-between gl-p-0 gl-text-gray-900"
        >
          {{ item.text }}
          <gl-badge v-if="item.count" pill size="sm" variant="info">{{ item.count }}</gl-badge>
          <kbd v-else-if="item.shortcut" class="flat">?</kbd>
        </button>
      </template>
    </gl-disclosure-dropdown-group>
  </gl-disclosure-dropdown>
</template>

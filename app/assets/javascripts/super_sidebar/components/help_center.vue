<script>
import { GlBadge, GlButton, GlDisclosureDropdown, GlDisclosureDropdownGroup } from '@gitlab/ui';
import GitlabVersionCheckBadge from '~/gitlab_version_check/components/gitlab_version_check_badge.vue';
import { helpPagePath } from '~/helpers/help_page_helper';
import { FORUM_URL, PROMO_URL } from '~/constants';
import { __ } from '~/locale';
import { STORAGE_KEY } from '~/whats_new/utils/notification';
import Tracking from '~/tracking';
import { DROPDOWN_Y_OFFSET, HELP_MENU_TRACKING_DEFAULTS, duoChatGlobalState } from '../constants';

export default {
  components: {
    GlBadge,
    GlButton,

    GlDisclosureDropdown,
    GlDisclosureDropdownGroup,
    GitlabVersionCheckBadge,
  },
  mixins: [Tracking.mixin({ property: 'nav_help_menu' })],
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
    terms: __('Terms and privacy'),
    privacy: __('Privacy statement'),
  },
  inject: ['isSaas'],
  props: {
    sidebarData: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      showWhatsNewNotification: this.shouldShowWhatsNewNotification(),
      duoChatGlobalState,
      toggleWhatsNewDrawer: null,
    };
  },
  computed: {
    itemGroups() {
      const groups = {
        helpLinks: {
          items: [
            {
              text: this.$options.i18n.help,
              href: helpPagePath(),
              extraAttrs: {
                ...this.trackingAttrs('help'),
              },
            },
            {
              text: this.$options.i18n.support,
              href: this.sidebarData.support_path,
              extraAttrs: {
                ...this.trackingAttrs('support'),
              },
            },
            {
              text: this.$options.i18n.docs,
              href: this.sidebarData.docs_path,
              extraAttrs: {
                ...this.trackingAttrs('gitlab_documentation'),
              },
            },
            {
              text: this.$options.i18n.plans,
              href: `${PROMO_URL}/pricing`,
              extraAttrs: {
                ...this.trackingAttrs('compare_gitlab_plans'),
              },
            },
            {
              text: this.$options.i18n.forum,
              href: FORUM_URL,
              extraAttrs: {
                ...this.trackingAttrs('community_forum'),
              },
            },
            {
              text: this.$options.i18n.contribute,
              href: helpPagePath('', { anchor: 'contribute-to-gitlab' }),
              extraAttrs: {
                ...this.trackingAttrs('contribute_to_gitlab'),
              },
            },
            {
              text: this.$options.i18n.feedback,
              href: `${PROMO_URL}/submit-feedback`,
              extraAttrs: {
                ...this.trackingAttrs('submit_feedback'),
              },
            },
            this.isSaas && {
              text: this.$options.i18n.privacy,
              href: `${PROMO_URL}/privacy`,
              extraAttrs: {
                ...this.trackingAttrs('privacy'),
              },
            },
            this.sidebarData.terms &&
              !this.isSaas && {
                text: this.$options.i18n.terms,
                href: this.sidebarData.terms,
                extraAttrs: {
                  ...this.trackingAttrs('terms'),
                },
              },
          ].filter(Boolean),
        },
        helpActions: {
          items: [
            {
              text: this.$options.i18n.shortcuts,
              action: () => {},
              extraAttrs: {
                class: 'js-shortcuts-modal-trigger',
                'data-track-action': 'click_button',
                'data-track-label': 'keyboard_shortcuts_help',
                'data-track-property': HELP_MENU_TRACKING_DEFAULTS['data-track-property'],
              },
              shortcut: '?',
            },
            this.sidebarData.display_whats_new && {
              text: this.$options.i18n.whatsnew,
              action: this.showWhatsNew,
              count:
                this.showWhatsNewNotification &&
                this.sidebarData.whats_new_most_recent_release_items_count,
              extraAttrs: {
                'data-track-action': 'click_button',
                'data-track-label': 'whats_new',
                'data-track-property': HELP_MENU_TRACKING_DEFAULTS['data-track-property'],
              },
            },
          ].filter(Boolean),
        },
      };

      if (this.sidebarData.show_version_check) {
        groups.versionCheck = {
          items: [
            {
              text: this.$options.i18n.version,
              href: helpPagePath('update/_index.md'),
              version: `${this.sidebarData.gitlab_version.major}.${this.sidebarData.gitlab_version.minor}`,
              extraAttrs: {
                ...this.trackingAttrs('version_help_dropdown'),
              },
            },
          ],
        };
      }

      return groups;
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

    async showWhatsNew() {
      this.showWhatsNewNotification = false;

      if (!this.toggleWhatsNewDrawer) {
        const { default: toggleWhatsNewDrawer } = await import(
          /* webpackChunkName: 'whatsNewApp' */ '~/whats_new'
        );
        this.toggleWhatsNewDrawer = toggleWhatsNewDrawer;
        this.toggleWhatsNewDrawer(this.sidebarData.whats_new_version_digest);
      } else {
        this.toggleWhatsNewDrawer();
      }
    },

    trackingAttrs(label) {
      return {
        ...HELP_MENU_TRACKING_DEFAULTS,
        'data-track-label': label,
      };
    },

    trackDropdownToggle(show) {
      this.track('click_toggle', {
        label: show ? 'show_help_dropdown' : 'hide_help_dropdown',
      });
    },
  },
  dropdownOffset: { mainAxis: DROPDOWN_Y_OFFSET },
};
</script>

<template>
  <gl-disclosure-dropdown
    :dropdown-offset="$options.dropdownOffset"
    @shown="trackDropdownToggle(true)"
    @hidden="trackDropdownToggle(false)"
  >
    <template #toggle>
      <gl-button
        category="tertiary"
        icon="question-o"
        class="super-sidebar-help-center-toggle btn-with-notification"
        data-testid="sidebar-help-button"
      >
        <span
          v-if="showWhatsNewNotification"
          data-testid="notification-dot"
          class="notification-dot-info"
        ></span>
        {{ $options.i18n.help }}
      </gl-button>
    </template>

    <gl-disclosure-dropdown-group
      v-if="sidebarData.show_version_check"
      :group="itemGroups.versionCheck"
    >
      <template #list-item="{ item }">
        <span class="gl-flex gl-flex-col gl-leading-24">
          <span class="gl-text-sm gl-font-bold">
            {{ item.text }}
            <gl-emoji data-name="rocket" />
          </span>
          <span>
            <span class="gl-mr-2">{{ item.version }}</span>
            <gitlab-version-check-badge v-if="updateSeverity" :status="updateSeverity" />
          </span>
        </span>
      </template>
    </gl-disclosure-dropdown-group>

    <gl-disclosure-dropdown-group
      :group="itemGroups.helpLinks"
      :bordered="sidebarData.show_version_check"
    />

    <gl-disclosure-dropdown-group :group="itemGroups.helpActions" bordered>
      <template #list-item="{ item }">
        <span class="-gl-my-1 gl-flex gl-items-center gl-justify-between">
          {{ item.text }}
          <gl-badge v-if="item.count" pill variant="info">{{ item.count }}</gl-badge>
          <kbd v-else-if="item.shortcut" class="flat">?</kbd>
        </span>
      </template>
    </gl-disclosure-dropdown-group>
  </gl-disclosure-dropdown>
</template>

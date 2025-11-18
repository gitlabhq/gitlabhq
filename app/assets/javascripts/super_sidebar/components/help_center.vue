<script>
import {
  GlBadge,
  GlButton,
  GlDisclosureDropdown,
  GlDisclosureDropdownGroup,
  GlTooltipDirective,
} from '@gitlab/ui';
import GitlabVersionCheckBadge from 'jh_else_ce/gitlab_version_check/components/gitlab_version_check_badge.vue';
import { helpPagePath } from '~/helpers/help_page_helper';
import { FORUM_URL, PROMO_URL, CONTRIBUTE_URL } from '~/constants';
import { __ } from '~/locale';
import Tracking from '~/tracking';
import { DROPDOWN_Y_OFFSET, HELP_MENU_TRACKING_DEFAULTS } from '../constants';

export default {
  components: {
    GlBadge,
    GlButton,
    GlDisclosureDropdown,
    GlDisclosureDropdownGroup,
    GitlabVersionCheckBadge,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  mixins: [Tracking.mixin({ property: 'nav_help_menu' })],
  i18n: {
    help: __('Help'),
    support: __('Support'),
    docs: __('GitLab documentation'),
    plans: __('Compare GitLab plans'),
    forum: __('GitLab community forum'),
    contribute: __('Contribute to GitLab'),
    feedback: __('Provide feedback'),
    shortcuts: __('Keyboard shortcuts'),
    version: __('Your GitLab version'),
    whatsnew: __("What's new"),
    terms: __('Terms and privacy'),
    privacy: __('Privacy statement'),
    whatsnewToast: __("What's new moved to Help."),
  },
  inject: ['isSaas', 'isIconOnly'],
  props: {
    sidebarData: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      showWhatsNewNotification: this.shouldShowWhatsNewNotification(),
      whatsNewMostRecentReleaseUnreadCount: this.calculateWhatsNewMostRecentReleaseUnreadCount(),
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
              href: this.sidebarData.compare_plans_url,
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
              href: CONTRIBUTE_URL,
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
            this.sidebarData.display_whats_new &&
              !this.showWhatsNewNotification && {
                text: this.$options.i18n.whatsnew,
                action: this.showWhatsNew,
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
      return (
        this.sidebarData.display_whats_new &&
        this.calculateWhatsNewMostRecentReleaseUnreadCount() > 0
      );
    },
    calculateWhatsNewMostRecentReleaseUnreadCount() {
      if (!this.sidebarData.display_whats_new) {
        return 0;
      }

      return (
        this.sidebarData.whats_new_most_recent_release_items_count -
        this.sidebarData.whats_new_read_articles.length
      );
    },

    async showWhatsNew() {
      if (!this.toggleWhatsNewDrawer) {
        const { default: toggleWhatsNewDrawer } = await import(
          /* webpackChunkName: 'whatsNewApp' */ '~/whats_new'
        );
        this.toggleWhatsNewDrawer = toggleWhatsNewDrawer;

        this.toggleWhatsNewDrawer(
          {
            versionDigest: this.sidebarData.whats_new_version_digest,
            initialReadArticles: this.sidebarData.whats_new_read_articles,
            markAsReadPath: this.sidebarData.whats_new_mark_as_read_path,
            mostRecentReleaseItemsCount: this.sidebarData.whats_new_most_recent_release_items_count,
          },
          this.hideWhatsNewNotification,
          this.updateWhatsNewNotificationBadge,
        );
      } else {
        this.toggleWhatsNewDrawer();
      }
    },

    hideWhatsNewNotification() {
      if (this.showWhatsNewNotification && this.whatsNewMostRecentReleaseUnreadCount === 0) {
        this.showWhatsNewNotification = false;
        this.$toast.show(this.$options.i18n.whatsnewToast);
      }
    },

    updateWhatsNewNotificationBadge(unreadCount) {
      this.whatsNewMostRecentReleaseUnreadCount = unreadCount;
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
  <div class="gl-flex gl-flex-col gl-gap-2">
    <gl-button
      v-if="showWhatsNewNotification"
      v-gl-tooltip.right="isIconOnly ? $options.i18n.whatsnew : ''"
      class="super-sidebar-whats-new super-sidebar-nav-item gl-w-full !gl-justify-start gl-gap-3 !gl-px-[0.375rem]"
      category="tertiary"
      icon="compass"
      data-testid="sidebar-whatsnew-button"
      data-track-action="click_button"
      data-track-label="whats_new"
      data-track-property="nav_whats_new"
      :aria-label="$options.i18n.whatsnew"
      :button-text-classes="{
        'gl-w-full gl-flex gl-items-center gl-justify-between gl-font-semibold !gl-text-default':
          !isIconOnly,
        'gl-hidden': isIconOnly,
      }"
      @click="showWhatsNew"
    >
      {{ $options.i18n.whatsnew }}

      <gl-badge
        variant="neutral"
        aria-hidden="true"
        data-testid="notification-count"
        class="gl-mr-1"
      >
        <span class="gl-m-1 gl-min-w-3">
          {{ whatsNewMostRecentReleaseUnreadCount }}
        </span>
      </gl-badge>
    </gl-button>

    <gl-disclosure-dropdown
      class="super-sidebar-help-center-dropdown"
      :dropdown-offset="$options.dropdownOffset"
      block
      @shown="trackDropdownToggle(true)"
      @hidden="trackDropdownToggle(false)"
    >
      <template #toggle>
        <gl-button
          v-gl-tooltip.right="isIconOnly ? $options.i18n.help : ''"
          category="tertiary"
          icon="question-o"
          class="super-sidebar-help-center-toggle super-sidebar-nav-item gl-w-full !gl-justify-start gl-gap-3 !gl-px-[0.375rem] !gl-py-2 gl-font-semibold"
          :button-text-classes="{ '!gl-text-default': !isIconOnly, 'gl-hidden': isIconOnly }"
          :aria-label="$options.i18n.help"
          data-testid="sidebar-help-button"
        >
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
              <gl-emoji data-name="rocket" aria-hidden="true" />
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
            <kbd v-if="item.shortcut" aria-hidden="true" class="flat">?</kbd>
          </span>
        </template>
      </gl-disclosure-dropdown-group>
    </gl-disclosure-dropdown>
  </div>
</template>

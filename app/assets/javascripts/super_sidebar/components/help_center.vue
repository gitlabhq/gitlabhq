<script>
import {
  GlDisclosureDropdown,
  GlDisclosureDropdownGroup,
  GlNavItem,
  GlTooltipDirective,
} from '@gitlab/ui';
import HelpCenterUpgradeSubscription from 'ee_component/super_sidebar/components/help_center_upgrade_subscription.vue';
import GitlabVersionCheckBadge from 'jh_else_ce/gitlab_version_check/components/gitlab_version_check_badge.vue';
import { helpPagePath } from '~/helpers/help_page_helper';
import { FORUM_URL, PROMO_URL, CONTRIBUTE_URL } from '~/constants';
import { __ } from '~/locale';
import Tracking from '~/tracking';
import GitlabExperiment from '~/experimentation/components/gitlab_experiment.vue';
import { isExperimentVariant } from '~/experimentation/utils';
import WhatsNewForYouMenuItem from '~/whats_new/components/whats_new_for_you_menu_item.vue';
import { HELP_MENU_TRACKING_DEFAULTS } from '../constants';

const WHATS_NEW_EXPERIMENT = 'whats_new_placement';
const WHATS_NEW_PLACEMENT = 'help_menu';

export default {
  name: 'HelpCenter',
  WHATS_NEW_EXPERIMENT,
  components: {
    GlDisclosureDropdown,
    GlDisclosureDropdownGroup,
    GitlabExperiment,
    GlNavItem,
    GitlabVersionCheckBadge,
    HelpCenterUpgradeSubscription,
    WhatsNewForYouMenuItem,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  mixins: [Tracking.mixin({ property: 'nav_help_menu', experiment: WHATS_NEW_EXPERIMENT })],
  i18n: {
    help: __('Help'),
    support: __('Support'),
    docs: __('GitLab documentation'),
    plans: __('Compare GitLab plans'),
    forum: __('GitLab community forum'),
    university: __('GitLab University'),
    contribute: __('Contribute to GitLab'),
    feedback: __('Provide feedback'),
    shortcuts: __('Keyboard shortcuts'),
    version: __('Your GitLab version'),
    terms: __('Terms and privacy'),
    privacy: __('Privacy statement'),
  },
  inject: ['isSaas', 'isIconOnly'],
  props: {
    sidebarData: {
      type: Object,
      required: true,
    },
  },
  computed: {
    showUpgradeSubscription() {
      return Boolean(this.sidebarData.free_group_upgrade_link);
    },
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
              text: this.$options.i18n.university,
              href: this.sidebarData.university_path,
              extraAttrs: {
                ...this.trackingAttrs('gitlab_university'),
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
          ],
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

      if (!show) return;

      const isCandidate = isExperimentVariant(WHATS_NEW_EXPERIMENT, 'candidate');
      if (this.sidebarData.display_whats_new && !isCandidate) {
        this.track('render_whats_new_for_you_menu_item', { property: WHATS_NEW_PLACEMENT });
      }
    },
  },
};
</script>

<template>
  <div class="gl-flex gl-flex-col gl-gap-2">
    <help-center-upgrade-subscription
      v-if="showUpgradeSubscription"
      :upgrade-link="sidebarData.free_group_upgrade_link"
    />

    <gl-disclosure-dropdown
      class="super-sidebar-help-center-dropdown"
      block
      @shown="trackDropdownToggle(true)"
      @hidden="trackDropdownToggle(false)"
    >
      <template #toggle="{ accessibilityAttributes }">
        <gl-nav-item
          v-gl-tooltip.right="isIconOnly ? $options.i18n.help : ''"
          icon="question-o"
          :is-icon-only="isIconOnly"
          :aria-label="$options.i18n.help"
          data-testid="sidebar-help-button"
          v-bind="accessibilityAttributes"
        >
          {{ $options.i18n.help }}
        </gl-nav-item>
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

      <gitlab-experiment :name="$options.WHATS_NEW_EXPERIMENT">
        <template #control>
          <whats-new-for-you-menu-item :sidebar-data="sidebarData" placement="help_menu" />
        </template>
      </gitlab-experiment>
    </gl-disclosure-dropdown>
  </div>
</template>

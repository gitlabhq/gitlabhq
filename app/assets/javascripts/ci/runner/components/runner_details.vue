<script>
import { GlIntersperse, GlLink } from '@gitlab/ui';
import { helpPagePath } from '~/helpers/help_page_helper';
import { s__ } from '~/locale';
import HelpPopover from '~/vue_shared/components/help_popover.vue';
import TimeAgo from '~/vue_shared/components/time_ago_tooltip.vue';
import { timeIntervalInWords } from '~/lib/utils/datetime_utility';
import { ACCESS_LEVEL_REF_PROTECTED, GROUP_TYPE, PROJECT_TYPE } from '../constants';
import RunnerDetail from './runner_detail.vue';
import RunnerGroups from './runner_groups.vue';
import RunnerProjects from './runner_projects.vue';
import RunnerTags from './runner_tags.vue';

export default {
  components: {
    GlIntersperse,
    GlLink,
    HelpPopover,
    RunnerDetail,
    RunnerMaintenanceNoteDetail: () =>
      import('ee_component/ci/runner/components/runner_maintenance_note_detail.vue'),
    RunnerGroups,
    RunnerProjects,
    RunnerUpgradeStatusBadge: () =>
      import('ee_component/ci/runner/components/runner_upgrade_status_badge.vue'),
    RunnerUpgradeStatusAlert: () =>
      import('ee_component/ci/runner/components/runner_upgrade_status_alert.vue'),
    RunnerTags,
    TimeAgo,
  },
  props: {
    runner: {
      type: Object,
      required: false,
      default: null,
    },
  },
  computed: {
    maximumTimeout() {
      const { maximumTimeout } = this.runner;
      if (typeof maximumTimeout !== 'number') {
        return null;
      }
      return timeIntervalInWords(maximumTimeout);
    },
    configTextProtected() {
      if (this.runner.accessLevel === ACCESS_LEVEL_REF_PROTECTED) {
        return s__('Runners|Protected');
      }
      return null;
    },
    configTextUntagged() {
      if (this.runner.runUntagged) {
        return s__('Runners|Runs untagged jobs');
      }
      return null;
    },
    tagList() {
      return this.runner.tagList || [];
    },
    isGroupRunner() {
      return this.runner?.runnerType === GROUP_TYPE;
    },
    isProjectRunner() {
      return this.runner?.runnerType === PROJECT_TYPE;
    },
    tokenExpirationHelpPopoverOptions() {
      return {
        title: s__('Runners|Runner authentication token expiration'),
      };
    },
    tokenExpirationHelpUrl() {
      return helpPagePath('ci/runners/configure_runners', {
        anchor: 'authentication-token-security',
      });
    },
  },
  ACCESS_LEVEL_REF_PROTECTED,
};
</script>

<template>
  <div>
    <runner-upgrade-status-alert class="gl-my-4" :runner="runner" />
    <div class="gl-pt-4">
      <dl
        class="gl-mb-0 gl-display-grid runner-details-grid-template"
        data-testid="runner-details-list"
      >
        <runner-detail :label="s__('Runners|Description')" :value="runner.description" />
        <runner-detail
          :label="s__('Runners|Last contact')"
          :empty-value="s__('Runners|Never contacted')"
        >
          <template v-if="runner.contactedAt" #value>
            <time-ago :time="runner.contactedAt" />
          </template>
        </runner-detail>
        <runner-detail :label="s__('Runners|Version')">
          <template v-if="runner.version" #value>
            {{ runner.version }}
            <runner-upgrade-status-badge size="sm" :runner="runner" />
          </template>
        </runner-detail>
        <runner-detail :label="s__('Runners|IP Address')" :value="runner.ipAddress" />
        <runner-detail :label="s__('Runners|Executor')" :value="runner.executorName" />
        <runner-detail :label="s__('Runners|Architecture')" :value="runner.architectureName" />
        <runner-detail :label="s__('Runners|Platform')" :value="runner.platformName" />
        <runner-detail :label="s__('Runners|Configuration')">
          <template v-if="configTextProtected || configTextUntagged" #value>
            <gl-intersperse>
              <span v-if="configTextProtected">{{ configTextProtected }}</span>
              <span v-if="configTextUntagged">{{ configTextUntagged }}</span>
            </gl-intersperse>
          </template>
        </runner-detail>
        <runner-detail :label="s__('Runners|Maximum job timeout')" :value="maximumTimeout" />
        <runner-detail :empty-value="s__('Runners|Never expires')">
          <template #label>
            {{ s__('Runners|Token expiry') }}
            <help-popover :options="tokenExpirationHelpPopoverOptions">
              <p>
                {{
                  s__(
                    'Runners|Runner authentication tokens will expire based on a set interval. They will automatically rotate once expired.',
                  )
                }}
              </p>
              <p class="gl-mb-0">
                <gl-link
                  :href="tokenExpirationHelpUrl"
                  target="_blank"
                  class="gl-reset-font-size"
                  >{{ __('Learn more') }}</gl-link
                >
              </p>
            </help-popover>
          </template>
          <template v-if="runner.tokenExpiresAt" #value>
            <time-ago :time="runner.tokenExpiresAt" />
          </template>
        </runner-detail>
        <runner-detail :label="s__('Runners|Tags')">
          <template v-if="tagList.length" #value>
            <runner-tags class="gl-vertical-align-middle" :tag-list="tagList" size="sm" />
          </template>
        </runner-detail>

        <runner-maintenance-note-detail
          class="gl-pt-4 gl-border-t-gray-100 gl-border-t-1 gl-border-t-solid"
          :value="runner.maintenanceNoteHtml"
        />
      </dl>
    </div>

    <runner-groups v-if="isGroupRunner" :runner="runner" />
    <runner-projects v-if="isProjectRunner" :runner="runner" />
  </div>
</template>

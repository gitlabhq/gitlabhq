<script>
import { GlIntersperse } from '@gitlab/ui';
import { s__ } from '~/locale';
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
    RunnerDetail,
    RunnerMaintenanceNoteDetail: () =>
      import('ee_component/runner/components/runner_maintenance_note_detail.vue'),
    RunnerGroups,
    RunnerProjects,
    RunnerUpgradeStatusBadge: () =>
      import('ee_component/runner/components/runner_upgrade_status_badge.vue'),
    RunnerUpgradeStatusAlert: () =>
      import('ee_component/runner/components/runner_upgrade_status_alert.vue'),
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
    isGroupRunner() {
      return this.runner?.runnerType === GROUP_TYPE;
    },
    isProjectRunner() {
      return this.runner?.runnerType === PROJECT_TYPE;
    },
  },
  ACCESS_LEVEL_REF_PROTECTED,
};
</script>

<template>
  <div>
    <runner-upgrade-status-alert class="gl-my-4" :runner="runner" />
    <div class="gl-pt-4">
      <dl class="gl-mb-0" data-testid="runner-details-list">
        <runner-detail :label="s__('Runners|Description')" :value="runner.description" />
        <runner-detail
          :label="s__('Runners|Last contact')"
          :empty-value="s__('Runners|Never contacted')"
        >
          <template #value>
            <time-ago v-if="runner.contactedAt" :time="runner.contactedAt" />
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
          <template #value>
            <gl-intersperse v-if="configTextProtected || configTextUntagged">
              <span v-if="configTextProtected">{{ configTextProtected }}</span>
              <span v-if="configTextUntagged">{{ configTextUntagged }}</span>
            </gl-intersperse>
          </template>
        </runner-detail>
        <runner-detail :label="s__('Runners|Maximum job timeout')" :value="maximumTimeout" />
        <runner-detail :label="s__('Runners|Tags')">
          <template #value>
            <runner-tags
              v-if="runner.tagList && runner.tagList.length"
              class="gl-vertical-align-middle"
              :tag-list="runner.tagList"
              size="sm"
            />
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

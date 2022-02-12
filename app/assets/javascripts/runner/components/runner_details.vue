<script>
import { GlTabs, GlTab, GlIntersperse } from '@gitlab/ui';
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
    GlTabs,
    GlTab,
    GlIntersperse,
    RunnerDetail,
    RunnerGroups,
    RunnerProjects,
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
  <gl-tabs>
    <gl-tab>
      <template #title>{{ s__('Runners|Details') }}</template>

      <template v-if="runner">
        <div class="gl-pt-4">
          <dl class="gl-mb-0">
            <runner-detail :label="s__('Runners|Description')" :value="runner.description" />
            <runner-detail
              :label="s__('Runners|Last contact')"
              :empty-value="s__('Runners|Never contacted')"
            >
              <template #value>
                <time-ago v-if="runner.contactedAt" :time="runner.contactedAt" />
              </template>
            </runner-detail>
            <runner-detail :label="s__('Runners|Version')" :value="runner.version" />
            <runner-detail :label="s__('Runners|IP Address')" :value="runner.ipAddress" />
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
          </dl>
        </div>

        <runner-groups v-if="isGroupRunner" :runner="runner" />
        <runner-projects v-if="isProjectRunner" :runner="runner" />
      </template>
    </gl-tab>
  </gl-tabs>
</template>

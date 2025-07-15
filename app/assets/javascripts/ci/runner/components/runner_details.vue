<script>
import { GlIntersperse, GlLink } from '@gitlab/ui';
import { helpPagePath } from '~/helpers/help_page_helper';
import { s__ } from '~/locale';
import HelpPopover from '~/vue_shared/components/help_popover.vue';
import TimeAgo from '~/vue_shared/components/time_ago_tooltip.vue';
import { timeIntervalInWords } from '~/lib/utils/datetime_utility';
import {
  ACCESS_LEVEL_REF_PROTECTED,
  GROUP_TYPE,
  PROJECT_TYPE,
  RUNNER_MANAGERS_HELP_URL,
  I18N_STATUS_NEVER_CONTACTED,
} from '../constants';
import RunnerDetail from './runner_detail.vue';
import RunnerGroups from './runner_groups.vue';
import RunnerProjects from './runner_projects.vue';
import RunnerTags from './runner_tags.vue';
import RunnerManagers from './runner_managers.vue';
import RunnerJobs from './runner_jobs.vue';

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
    RunnerTags,
    RunnerManagers,
    RunnerJobs,
    TimeAgo,
  },
  props: {
    runnerId: {
      type: String,
      required: true,
    },
    runner: {
      type: Object,
      required: false,
      default: null,
    },
    showAccessHelp: {
      type: Boolean,
      required: false,
      default: false,
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
  RUNNER_MANAGERS_HELP_URL,
  I18N_STATUS_NEVER_CONTACTED,
};
</script>

<template>
  <div v-if="runner">
    <div class="md:gl-columns-2">
      <dl
        class="gl-mb-0 gl-flex gl-flex-col gl-gap-x-5 gl-gap-y-1 md:gl-grid md:gl-grid-cols-[auto_1fr] md:gl-gap-y-3"
      >
        <runner-detail :label="s__('Runners|Description')" :value="runner.description" />
        <runner-detail
          :label="s__('Runners|Last contact')"
          :empty-value="$options.I18N_STATUS_NEVER_CONTACTED"
        >
          <template v-if="runner.contactedAt" #value>
            <time-ago :time="runner.contactedAt" />
          </template>
        </runner-detail>
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
                <gl-link :href="tokenExpirationHelpUrl" target="_blank">{{
                  __('Learn more')
                }}</gl-link>
              </p>
            </help-popover>
          </template>
          <template v-if="runner.tokenExpiresAt" #value>
            <time-ago :time="runner.tokenExpiresAt" />
          </template>
        </runner-detail>
        <runner-detail :label="s__('Runners|Tags')">
          <template v-if="tagList.length" #value>
            <runner-tags class="gl-align-middle" :tag-list="tagList" size="sm" />
          </template>
        </runner-detail>

        <runner-maintenance-note-detail
          class="gl-border-t-1 gl-border-t-default gl-pt-4 gl-border-t-solid"
          :runner="runner"
          :value="runner.maintenanceNoteHtml"
        />
      </dl>
    </div>

    <div class="gl-mt-6 gl-flex gl-flex-col gl-gap-5">
      <runner-groups v-if="isGroupRunner" :runner="runner" />
      <runner-projects v-if="isProjectRunner" :runner="runner" />
      <runner-managers :runner="runner" />
      <runner-jobs :runner-id="runnerId" :show-access-help="showAccessHelp" />
    </div>
  </div>
</template>

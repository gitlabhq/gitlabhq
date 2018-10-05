<script>
  import { mapGetters, mapState } from 'vuex';
  import CiHeader from '~/vue_shared/components/header_ci_component.vue';
  import Callout from '~/vue_shared/components/callout.vue';
  // ee-only start
  import SharedRunner from 'ee/jobs/components/shared_runner_limit_block.vue';
  // ee-only end
  import EmptyState from './empty_state.vue';
  import EnvironmentsBlock from './environments_block.vue';
  import ErasedBlock from './erased_block.vue';
  import StuckBlock from './stuck_block.vue';

  export default {
    name: 'JobPageApp',
    components: {
      CiHeader,
      Callout,
      EmptyState,
      EnvironmentsBlock,
      ErasedBlock,
      StuckBlock,
      SharedRunner,
    },
    props: {
      runnerHelpUrl: {
        type: String,
        required: false,
        default: null,
      },
    },
    computed: {
      ...mapState(['isLoading', 'job']),
      ...mapGetters([
        'headerActions',
        'headerTime',
        'shouldRenderCalloutMessage',
        'jobHasStarted',
        'hasEnvironment',
        'isJobStuck',
        'shouldRenderSharedRunnerLimitWarning',
        'hasTrace',
        'emptyStateIllustration',
      ]),
    },
  };
</script>
<template>
  <div>
    <gl-loading-icon
      v-if="isLoading"
      :size="2"
      class="prepend-top-20"
    />

    <template v-else>
      <!-- Header Section -->
      <header>
        <div class="js-build-header build-header top-area">
          <ci-header
            :status="job.status"
            :item-id="job.id"
            :time="headerTime"
            :user="job.user"
            :actions="headerActions"
            :has-sidebar-button="true"
            :should-render-triggered-label="jobHasStarted"
            :item-name="__('Job')"
          />
        </div>

        <callout
          v-if="shouldRenderCalloutMessage"
          :message="job.callout_message"
        />
      </header>
      <!-- EO Header Section -->

      <!-- Body Section -->
      <stuck-block
        v-if="isJobStuck"
        class="js-job-stuck"
        :has-no-runners-for-project="job.runners.available"
        :tags="job.tags"
        :runners-path="runnerHelpUrl"
      />

      <shared-runner
        v-if="shouldRenderSharedRunnerLimitWarning"
        class="js-shared-runner-limit"
        :quota-used="job.runners.quota.used"
        :quota-limit="job.runners.quota.limit"
        :runners-path="runnerHelpUrl"
      />

      <environments-block
        v-if="hasEnvironment"
        class="js-job-environment"
        :deployment-status="job.deployment_status"
        :icon-status="job.status"
      />

      <erased-block
        v-if="job.erased"
        class="js-job-erased"
        :user="job.erased_by"
        :erased-at="job.erased_at"
      />

      <!--job log -->
      <!-- EO job log -->

      <!--empty state -->
      <empty-state
        v-if="!hasTrace"
        class="js-job-empty-state"
        :illustration-path="emptyStateIllustration.image"
        :illustration-size-class="emptyStateIllustration.size"
        :title="emptyStateIllustration.title"
        :content="emptyStateIllustration.content"
        :action="job.status.action"
      />
      <!-- EO empty state -->

      <!-- EO Body Section -->
    </template>
  </div>
</template>

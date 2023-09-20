<script>
import { isEmpty } from 'lodash';
// eslint-disable-next-line no-restricted-imports
import { mapActions, mapGetters, mapState } from 'vuex';
import { forwardDeploymentFailureModalId } from '~/ci/constants';
import { filterAnnotations } from '~/ci/job_details/utils';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import ArtifactsBlock from './artifacts_block.vue';
import CommitBlock from './commit_block.vue';
import ExternalLinksBlock from './external_links_block.vue';
import JobsContainer from './jobs_container.vue';
import JobRetryForwardDeploymentModal from './job_retry_forward_deployment_modal.vue';
import JobSidebarDetailsContainer from './sidebar_job_details_container.vue';
import SidebarHeader from './sidebar_header.vue';
import StagesDropdown from './stages_dropdown.vue';
import TriggerBlock from './trigger_block.vue';

export default {
  name: 'JobSidebar',
  forwardDeploymentFailureModalId,
  components: {
    ArtifactsBlock,
    CommitBlock,
    JobsContainer,
    JobRetryForwardDeploymentModal,
    JobSidebarDetailsContainer,
    SidebarHeader,
    StagesDropdown,
    TriggerBlock,
    ExternalLinksBlock,
  },
  props: {
    artifactHelpUrl: {
      type: String,
      required: false,
      default: '',
    },
  },
  computed: {
    ...mapGetters(['hasForwardDeploymentFailure']),
    ...mapState(['job', 'stages', 'jobs', 'selectedStage']),
    hasArtifact() {
      // the artifact object will always have a locked property
      return Object.keys(this.job.artifact).length > 1;
    },
    artifact() {
      return convertObjectPropsToCamelCase(this.job.artifact, { deep: true });
    },
    hasExternalLinks() {
      return this.externalLinks.length > 0;
    },
    hasTriggers() {
      return !isEmpty(this.job.trigger);
    },
    commit() {
      return this.job?.pipeline?.commit || {};
    },
    selectedStageData() {
      return this.stages.find((val) => val.name === this.selectedStage);
    },
    shouldShowJobRetryForwardDeploymentModal() {
      return this.job.retry_path && this.hasForwardDeploymentFailure;
    },
    externalLinks() {
      return filterAnnotations(this.job.annotations, 'external_link');
    },
  },
  watch: {
    job(value, oldValue) {
      const hasNewStatus = value.status.text !== oldValue.status.text;
      const isCurrentStage = value?.stage === this.selectedStage;

      if (hasNewStatus && isCurrentStage) {
        this.fetchJobsForStage(this.selectedStageData);
      }
    },
  },
  methods: {
    ...mapActions(['fetchJobsForStage']),
  },
};
</script>
<template>
  <aside class="right-sidebar build-sidebar" data-offset-top="101" data-spy="affix">
    <div class="sidebar-container">
      <div class="blocks-container gl-p-4">
        <sidebar-header
          class="block gl-pb-4! gl-mb-2"
          :rest-job="job"
          :job-id="job.id"
          @updateVariables="$emit('updateVariables')"
        />

        <job-sidebar-details-container class="block gl-mb-2" />

        <artifacts-block
          v-if="hasArtifact"
          class="block gl-mb-2"
          :artifact="artifact"
          :help-url="artifactHelpUrl"
        />

        <external-links-block
          v-if="hasExternalLinks"
          class="block gl-mb-2"
          :external-links="externalLinks"
        />

        <trigger-block v-if="hasTriggers" class="block gl-mb-2" :trigger="job.trigger" />

        <commit-block class="block gl-mb-2" :commit="commit" :merge-request="job.merge_request" />

        <stages-dropdown
          v-if="job.pipeline"
          class="block gl-mb-2"
          :pipeline="job.pipeline"
          :selected-stage="selectedStage"
          :stages="stages"
          @requestSidebarStageDropdown="fetchJobsForStage"
        />

        <jobs-container v-if="jobs.length" :job-id="job.id" :jobs="jobs" />
      </div>
    </div>
    <job-retry-forward-deployment-modal
      v-if="shouldShowJobRetryForwardDeploymentModal"
      :modal-id="$options.forwardDeploymentFailureModalId"
      :href="job.retry_path"
    />
  </aside>
</template>

<script>
import Visibility from 'visibilityjs';
import { mapState, mapGetters } from 'vuex';
import icon from '~/vue_shared/components/icon.vue';
import tooltip from '~/vue_shared/directives/tooltip';
import timeAgoMixin from '~/vue_shared/mixins/timeago';
import Poll from '../../lib/utils/poll';
import service from '../services';
import CiIcon from '../../vue_shared/components/ci_icon.vue';
import userAvatarImage from '../../vue_shared/components/user_avatar/user_avatar_image.vue';

export default {
  components: {
    icon,
    userAvatarImage,
    CiIcon,
  },
  directives: {
    tooltip,
  },
  mixins: [timeAgoMixin],
  props: {
    file: {
      type: Object,
      required: false,
      default: null,
    },
  },
  data() {
    return {
      lastCommitFormatedAge: null,
      lastCommitPipeline: null,
    };
  },
  computed: {
    ...mapState(['currentBranchId', 'currentProjectId']),
    ...mapGetters(['currentProject', 'lastCommit']),
  },
  watch: {
    lastCommit(newCommit) {
      this.$store.dispatch('getCommitPipeline', {
        projectId: this.currentProjectId,
        branchId: this.currentBranchId,
        commitSha: newCommit.id,
      });

      if (!this.poll) {
        this.initPipelinePolling();
      }
    },
  },
  mounted() {
    this.startTimer();
  },
  beforeDestroy() {
    if (this.intervalId) {
      clearInterval(this.intervalId);
    }
    if (this.poll) {
      this.poll.stop();
    }
  },
  methods: {
    startTimer() {
      this.intervalId = setInterval(() => {
        this.commitAgeUpdate();
        this.lastCommitPipeline =
          this.lastCommit && this.lastCommit.pipeline && this.lastCommit.pipeline.details
            ? this.lastCommit.pipeline
            : null;
      }, 1000);
    },
    initPipelinePolling() {
      this.poll = new Poll({
        resource: this,
        method: 'pipelinePoll',
        successCallback: this.handlePipelinesResult,
        errorCallback(err) {
          throw new Error(err);
        },
      });

      this.service = service;

      if (!Visibility.hidden()) {
        this.poll.makeRequest();
      }

      Visibility.change(() => {
        if (!Visibility.hidden()) {
          this.poll.restart();
        } else {
          this.poll.stop();
        }
      });
    },
    pipelinePoll() {
      return this.service.commitPipelines(this.currentProjectId, this.lastCommit.id);
    },
    handlePipelinesResult(data) {
      this.$store.dispatch('handleCommitPipeline', data);
    },
    commitAgeUpdate() {
      if (this.lastCommit) {
        this.lastCommitFormatedAge = this.timeFormated(this.lastCommit.committed_date);
      }
    },
    getCommitPath(shortSha) {
      return `${this.currentProject.web_url}/commit/${shortSha}`;
    },
  },
};
</script>

<template>
  <footer class="ide-status-bar">
    <div
      class="ide-status-branch"
      v-if="lastCommit && lastCommitFormatedAge"
    >
      <span
        class="ide-status-pipeline"
        v-if="lastCommitPipeline"
      >
        <ci-icon
          :status="lastCommitPipeline.details.status"
          v-tooltip
          :title="lastCommitPipeline.details.status.text"
        />
        Pipeline
        <a :href="lastCommitPipeline.details.status.details_path">#{{ lastCommitPipeline.id }}</a>
        {{ lastCommitPipeline.details.status.text }}
        for
      </span>

      <icon
        name="commit"
      />
      <a
        v-tooltip
        class="commit-sha"
        :title="lastCommit.message"
        :href="getCommitPath(lastCommit.short_id)"
      >{{ lastCommit.short_id }}</a>
      by
      {{ lastCommit.author_name }}
      <time
        v-tooltip
        data-placement="top"
        data-container="body"
        :datetime="lastCommit.committed_date"
        :title="tooltipTitle(lastCommit.committed_date)"
      >
        {{ lastCommitFormatedAge }}
      </time>
    </div>
    <div
      v-if="file"
      class="ide-status-file"
    >
      {{ file.name }}
    </div>
    <div
      v-if="file"
      class="ide-status-file"
    >
      {{ file.eol }}
    </div>
    <div
      class="ide-status-file"
      v-if="file && !file.binary">
      {{ file.editorRow }}:{{ file.editorColumn }}
    </div>
    <div
      v-if="file"
      class="ide-status-file"
    >
      {{ file.fileLanguage }}
    </div>
  </footer>
</template>

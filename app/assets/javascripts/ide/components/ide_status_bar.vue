<script>
import { mapState, mapGetters } from 'vuex';
import icon from '~/vue_shared/components/icon.vue';
import tooltip from '~/vue_shared/directives/tooltip';
import timeAgoMixin from '~/vue_shared/mixins/timeago';
import SmartInterval from '~/smart_interval';
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
    ...mapState(['currentBranchId']),
    ...mapGetters(['currentProject', 'lastCommit']),
  },
  watch: {
    lastCommitPipeline() {
      this.lastCommitPipeline.statusObject = this.pipelineStatus(this.lastCommitPipeline);
    },
  },
  mounted() {
    this.startTimer();
    this.initPolling();
  },
  beforeDestroy() {
    if (this.intervalId) {
      clearInterval(this.intervalId);
    }
    if (!this.pollingInterval) {
      this.pollingInterval.cancel();
    }
  },
  methods: {
    initPolling() {
      if (!this.pollingInterval) {
        this.pollingInterval = new SmartInterval({
          callback: this.checkPipelineStatus.bind(this),
          immediateExecution: true,
          startingInterval: 10000,
          maxInterval: 60000,
          hiddenInterval: 120000,
          incrementByFactorOf: 1.5,
        });
      }
    },
    checkPipelineStatus() {
      let result;

      if (this.lastCommit && this.currentProject.id) {
        result = this.$store.dispatch('getLastCommitPipeline', {
          projectId: this.currentProject.path_with_namespace,
          projectIdNumber: this.currentProject.id,
          branchId: this.currentBranchId,
        });
      } else {
        result = new Promise(resolve => {
          resolve();
        });
      }

      return result;
    },
    pipelineStatus(pipeline) {
      // Status needed for <ci-icon>
      // {
      //   details_path: "/gitlab-org/gitlab-ce/pipelines/8150156" // url
      //   group:"running" // used for CSS class
      //   icon: "icon_status_running" // used to render the icon
      //   label:"running" // used for potential tooltip
      //   text:"running" // text rendered
      // }
      let status;
      if (pipeline) {
        status = {
          id: pipeline.id,
          details_path: `/${this.currentProject.path_with_namespace}/pipelines/${pipeline.id}`,
          group: pipeline.status,
          icon: `status_${pipeline.status}`,
          label: pipeline.status,
          text: pipeline.status,
        };
      } else {
        status = {};
      }

      return status;
    },
    startTimer() {
      this.intervalId = setInterval(() => {
        this.commitAgeUpdate();
        this.lastCommitPipeline =
          this.lastCommit && this.lastCommit.pipeline ? this.lastCommit.pipeline : null;
      }, 1000);
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
          :status="lastCommitPipeline.statusObject "
          :title="lastCommitPipeline.statusObject.text" />
        Pipeline
        <a :href="lastCommitPipeline.statusObject.details_path">#{{ lastCommitPipeline.id }}</a>
        {{ lastCommitPipeline.statusObject.text }}
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

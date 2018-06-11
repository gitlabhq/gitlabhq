<script>
import { mapActions, mapState, mapGetters } from 'vuex';
import icon from '~/vue_shared/components/icon.vue';
import tooltip from '~/vue_shared/directives/tooltip';
import timeAgoMixin from '~/vue_shared/mixins/timeago';
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
    };
  },
  computed: {
    ...mapState(['currentBranchId', 'currentProjectId']),
    ...mapGetters(['currentProject', 'lastCommit']),
    ...mapState('pipelines', ['latestPipeline']),
  },
  watch: {
    lastCommit() {
      this.initPipelinePolling();
    },
  },
  mounted() {
    this.startTimer();
  },
  beforeDestroy() {
    if (this.intervalId) {
      clearInterval(this.intervalId);
    }

    this.stopPipelinePolling();
  },
  methods: {
    ...mapActions('pipelines', ['fetchLatestPipeline', 'stopPipelinePolling']),
    startTimer() {
      this.intervalId = setInterval(() => {
        this.commitAgeUpdate();
      }, 1000);
    },
    initPipelinePolling() {
      if (this.lastCommit) {
        this.fetchLatestPipeline();
      }
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
        v-if="latestPipeline && latestPipeline.details"
      >
        <ci-icon
          :status="latestPipeline.details.status"
          v-tooltip
          :title="latestPipeline.details.status.text"
        />
        Pipeline
        <a
          class="monospace"
          :href="latestPipeline.details.status.details_path">#{{ latestPipeline.id }}</a>
        {{ latestPipeline.details.status.text }}
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

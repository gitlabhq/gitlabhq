<script>
import { mapActions, mapState, mapGetters } from 'vuex';
import icon from '~/vue_shared/components/icon.vue';
import CiIcon from '../../vue_shared/components/ci_icon.vue';
import userAvatarImage from '../../vue_shared/components/user_avatar/user_avatar_image.vue';
import Timeago from '../../vue_shared/components/time_ago_auto.vue';
import tooltip from '../../vue_shared/directives/tooltip';
import { rightSidebarViews } from '../constants';

export default {
  components: {
    icon,
    userAvatarImage,
    CiIcon,
    Timeago,
  },
  directives: { tooltip },
  props: {
    file: {
      type: Object,
      required: false,
      default: null,
    },
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
  beforeDestroy() {
    this.stopPipelinePolling();
  },
  methods: {
    ...mapActions(['setRightPane']),
    ...mapActions('pipelines', ['fetchLatestPipeline', 'stopPipelinePolling']),
    initPipelinePolling() {
      if (this.lastCommit) {
        this.fetchLatestPipeline();
      }
    },
    getCommitPath(shortSha) {
      return `${this.currentProject.web_url}/commit/${shortSha}`;
    },
  },
  rightSidebarViews,
};
</script>

<template>
  <footer class="ide-status-bar">
    <div
      v-if="lastCommit"
      class="ide-status-branch"
    >
      <span
        v-if="latestPipeline && latestPipeline.details"
        class="ide-status-pipeline"
      >
        <button
          type="button"
          class="p-0 border-0 h-50"
          @click="setRightPane($options.rightSidebarViews.pipelines)"
        >
          <ci-icon
            v-tooltip
            :status="latestPipeline.details.status"
            :title="latestPipeline.details.status.text"
          />
        </button>
        Pipeline
        <a
          :href="latestPipeline.details.status.details_path"
          class="monospace">#{{ latestPipeline.id }}</a>
        {{ latestPipeline.details.status.text }}
        for
      </span>

      <icon
        name="commit"
      />
      <a
        v-tooltip
        :title="lastCommit.message"
        :href="getCommitPath(lastCommit.short_id)"
        class="commit-sha"
      >{{ lastCommit.short_id }}</a>
      by
      {{ lastCommit.author_name }}
      <timeago
        :time="lastCommit.committed_date"
      />
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
      v-if="file && !file.binary"
      class="ide-status-file">
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

<script>
/* eslint-disable @gitlab/vue-i18n/no-bare-strings */
import { mapActions, mapState, mapGetters } from 'vuex';
import IdeStatusList from 'ee_else_ce/ide/components/ide_status_list.vue';
import icon from '~/vue_shared/components/icon.vue';
import tooltip from '~/vue_shared/directives/tooltip';
import timeAgoMixin from '~/vue_shared/mixins/timeago';
import CiIcon from '../../vue_shared/components/ci_icon.vue';
import userAvatarImage from '../../vue_shared/components/user_avatar/user_avatar_image.vue';
import { rightSidebarViews } from '../constants';

export default {
  components: {
    icon,
    userAvatarImage,
    CiIcon,
    IdeStatusList,
  },
  directives: {
    tooltip,
  },
  mixins: [timeAgoMixin],
  data() {
    return {
      lastCommitFormattedAge: null,
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
    ...mapActions('rightPane', {
      openRightPane: 'open',
    }),
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
        this.lastCommitFormattedAge = this.timeFormatted(this.lastCommit.committed_date);
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
    <div v-if="lastCommit" class="ide-status-branch">
      <span v-if="latestPipeline && latestPipeline.details" class="ide-status-pipeline">
        <button
          type="button"
          class="p-0 border-0 h-50"
          @click="openRightPane($options.rightSidebarViews.pipelines)"
        >
          <ci-icon
            v-tooltip
            :status="latestPipeline.details.status"
            :title="latestPipeline.details.status.text"
          />
        </button>
        Pipeline
        <a :href="latestPipeline.details.status.details_path" class="monospace"
          >#{{ latestPipeline.id }}</a
        >
        {{ latestPipeline.details.status.text }} for
      </span>

      <icon name="commit" />
      <a
        v-tooltip
        :title="lastCommit.message"
        :href="getCommitPath(lastCommit.short_id)"
        class="commit-sha"
        >{{ lastCommit.short_id }}</a
      >
      by
      <user-avatar-image
        css-classes="ide-status-avatar"
        :size="18"
        :img-src="latestPipeline && latestPipeline.commit.author_gravatar_url"
        :img-alt="lastCommit.author_name"
        :tooltip-text="lastCommit.author_name"
      />
      {{ lastCommit.author_name }}
      <time
        v-tooltip
        :datetime="lastCommit.committed_date"
        :title="tooltipTitle(lastCommit.committed_date)"
        data-placement="top"
        data-container="body"
        >{{ lastCommitFormattedAge }}</time
      >
    </div>
    <ide-status-list class="ml-auto" />
  </footer>
</template>

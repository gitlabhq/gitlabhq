<script>
/* eslint-disable @gitlab/vue-require-i18n-strings */
import { GlIcon, GlTooltipDirective } from '@gitlab/ui';
// eslint-disable-next-line no-restricted-imports
import { mapActions, mapState, mapGetters } from 'vuex';
import timeAgoMixin from '~/vue_shared/mixins/timeago';
import CiIcon from '~/vue_shared/components/ci_icon/ci_icon.vue';
import UserAvatarImage from '~/vue_shared/components/user_avatar/user_avatar_image.vue';
import { rightSidebarViews } from '../constants';
import IdeStatusList from './ide_status_list.vue';
import IdeStatusMr from './ide_status_mr.vue';

export default {
  components: {
    GlIcon,
    UserAvatarImage,
    CiIcon,
    IdeStatusList,
    IdeStatusMr,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  mixins: [timeAgoMixin],
  data() {
    return {
      lastCommitFormattedAge: null,
    };
  },
  computed: {
    ...mapState(['currentBranchId', 'currentProjectId']),
    ...mapGetters(['currentProject', 'lastCommit', 'currentMergeRequest']),
    ...mapState('pipelines', ['latestPipeline']),
  },
  watch: {
    lastCommit: {
      handler() {
        this.initPipelinePolling();
      },
      immediate: true,
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
          class="p-0 border-0 bg-transparent"
          @click="openRightPane($options.rightSidebarViews.pipelines)"
        >
          <ci-icon
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

      <gl-icon name="commit" />
      <a
        v-gl-tooltip
        :title="lastCommit.message"
        :href="getCommitPath(lastCommit.short_id)"
        class="commit-sha"
        data-testid="commit-sha-content"
        >{{ lastCommit.short_id }}</a
      >
      by
      <user-avatar-image
        css-classes="ide-status-avatar"
        :size="16"
        :img-src="latestPipeline && latestPipeline.commit.author_gravatar_url"
        :img-alt="lastCommit.author_name"
        :tooltip-text="lastCommit.author_name"
      />
      {{ lastCommit.author_name }}
      <time
        v-gl-tooltip
        :datetime="lastCommit.committed_date"
        :title="tooltipTitle(lastCommit.committed_date)"
        data-placement="top"
        data-container="body"
        >{{ lastCommitFormattedAge }}</time
      >
    </div>
    <ide-status-mr
      v-if="currentMergeRequest"
      class="mx-3"
      :url="currentMergeRequest.web_url"
      :text="currentMergeRequest.references.short"
    />
    <ide-status-list class="ml-auto" />
  </footer>
</template>

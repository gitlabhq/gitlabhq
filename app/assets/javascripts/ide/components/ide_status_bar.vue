<script>
import { mapState, mapGetters } from 'vuex';
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
    ...mapState(['currentBranchId']),
    ...mapGetters(['currentProject', 'lastCommit']),
  },
  mounted() {
    this.startTimer();
  },
  beforeDestroy() {
    if (this.intervalId) {
      clearInterval(this.intervalId);
    }
  },
  methods: {
    startTimer() {
      this.intervalId = setInterval(() => {
        this.commitAgeUpdate();
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

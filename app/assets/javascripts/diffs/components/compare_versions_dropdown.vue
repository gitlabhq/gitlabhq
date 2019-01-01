<script>
import Icon from '~/vue_shared/components/icon.vue';
import { n__, __ } from '~/locale';
import TimeAgo from '~/vue_shared/components/time_ago_tooltip.vue';

export default {
  components: {
    Icon,
    TimeAgo,
  },
  props: {
    otherVersions: {
      type: Array,
      required: false,
      default: () => [],
    },
    mergeRequestVersion: {
      type: Object,
      required: false,
      default: null,
    },
    startVersion: {
      type: Object,
      required: false,
      default: null,
    },
    targetBranch: {
      type: Object,
      required: false,
      default: null,
    },
    showCommitCount: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    baseVersion() {
      return {
        name: 'hii',
        versionIndex: -1,
      };
    },
    targetVersions() {
      if (this.mergeRequestVersion) {
        return this.otherVersions;
      }
      return [...this.otherVersions, this.targetBranch];
    },
    selectedVersionName() {
      const selectedVersion = this.startVersion || this.targetBranch || this.mergeRequestVersion;
      return this.versionName(selectedVersion);
    },
  },
  methods: {
    commitsText(version) {
      return n__(
        `${version.commits_count} commit,`,
        `${version.commits_count} commits,`,
        version.commits_count,
      );
    },
    href(version) {
      if (this.showCommitCount) {
        return version.version_path;
      }
      return version.compare_path;
    },
    versionName(version) {
      if (this.isLatest(version)) {
        return __('latest version');
      }
      if (this.targetBranch && (this.isBase(version) || !version)) {
        return this.targetBranch.branchName;
      }
      return `version ${version.version_index}`;
    },
    isActive(version) {
      if (!version) {
        return false;
      }

      if (this.targetBranch) {
        return (
          (this.isBase(version) && !this.startVersion) ||
          (this.startVersion && this.startVersion.version_index === version.version_index)
        );
      }

      return version.version_index === this.mergeRequestVersion.version_index;
    },
    isBase(version) {
      if (!version || !this.targetBranch) {
        return false;
      }
      return version.versionIndex === -1;
    },
    isLatest(version) {
      return (
        this.mergeRequestVersion && version.version_index === this.targetVersions[0].version_index
      );
    },
  },
};
</script>

<template>
  <span class="dropdown inline">
    <a
      class="dropdown-menu-toggle btn btn-default w-100"
      data-toggle="dropdown"
      aria-expanded="false"
    >
      <span> {{ selectedVersionName }} </span>
      <icon :size="12" name="angle-down" class="position-absolute" />
    </a>
    <div class="dropdown-menu dropdown-select dropdown-menu-selectable">
      <div class="dropdown-content">
        <ul>
          <li v-for="version in targetVersions" :key="version.id">
            <a :class="{ 'is-active': isActive(version) }" :href="href(version)">
              <div>
                <strong>
                  {{ versionName(version) }}
                  <template v-if="isBase(version)">
                    (base)
                  </template>
                </strong>
              </div>
              <div>
                <small class="commit-sha"> {{ version.short_commit_sha }} </small>
              </div>
              <div>
                <small>
                  <template v-if="showCommitCount">
                    {{ commitsText(version) }}
                  </template>
                  <time-ago
                    v-if="version.created_at"
                    :time="version.created_at"
                    class="js-timeago js-timeago-render"
                  />
                </small>
              </div>
            </a>
          </li>
        </ul>
      </div>
    </div>
  </span>
</template>

<style>
.dropdown {
  min-width: 0;
  max-height: 170px;
}
</style>

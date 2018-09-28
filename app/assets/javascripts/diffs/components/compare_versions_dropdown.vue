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
        `${version.commitsCount} commit,`,
        `${version.commitsCount} commits,`,
        version.commitsCount,
      );
    },
    href(version) {
      if (this.showCommitCount) {
        return version.versionPath;
      }
      return version.comparePath;
    },
    versionName(version) {
      if (this.isLatest(version)) {
        return __('latest version');
      }
      if (this.targetBranch && (this.isBase(version) || !version)) {
        return this.targetBranch.branchName;
      }
      return `version ${version.versionIndex}`;
    },
    isActive(version) {
      if (!version) {
        return false;
      }

      if (this.targetBranch) {
        return (
          (this.isBase(version) && !this.startVersion) ||
          (this.startVersion && this.startVersion.versionIndex === version.versionIndex)
        );
      }

      return version.versionIndex === this.mergeRequestVersion.versionIndex;
    },
    isBase(version) {
      if (!version || !this.targetBranch) {
        return false;
      }
      return version.versionIndex === -1;
    },
    isLatest(version) {
      return (
        this.mergeRequestVersion && version.versionIndex === this.targetVersions[0].versionIndex
      );
    },
  },
};
</script>

<template>
  <span class="dropdown inline">
    <a
      class="dropdown-toggle btn btn-default"
      data-toggle="dropdown"
      aria-expanded="false"
    >
      <span>
        {{ selectedVersionName }}
      </span>
      <Icon
        :size="12"
        name="angle-down"
      />
    </a>
    <div class="dropdown-menu dropdown-select dropdown-menu-selectable">
      <div class="dropdown-content">
        <ul>
          <li
            v-for="version in targetVersions"
            :key="version.id"
          >
            <a
              :class="{ 'is-active': isActive(version) }"
              :href="href(version)"
            >
              <div>
                <strong>
                  {{ versionName(version) }}
                  <template v-if="isBase(version)">
                    (base)
                  </template>
                </strong>
              </div>
              <div>
                <small class="commit-sha">
                  {{ version.truncatedCommitSha }}
                </small>
              </div>
              <div>
                <small>
                  <template v-if="showCommitCount">
                    {{ commitsText(version) }}
                  </template>
                  <time-ago
                    v-if="version.createdAt"
                    :time="version.createdAt"
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

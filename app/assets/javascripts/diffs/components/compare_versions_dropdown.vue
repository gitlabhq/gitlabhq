<script>
import Icon from '~/vue_shared/components/icon.vue';
import TimeAgo from '~/vue_shared/components/time_ago_tooltip.vue';

export default {
  components: {
    Icon,
    TimeAgo,
  },
  props: {
    otherVersions: {
      type: Array,
      default: () => [],
    },
    latestVersion: {
      type: Object,
      required: false,
      default: undefined,
    },
    baseVersion: {
      type: Object,
      required: false,
      default: undefined,
    },
    selectedIndex: {
      type: Number,
      default: 0,
    },
  },
  computed: {
    targetVersions() {
      if (this.latestVersion) {
        return [
          this.latestVersion,
          ...this.otherVersions,
        ];
      }
      return [
        ...this.otherVersions,
        this.baseVersion,
      ];
    },
    baseVersionSelected() {
      return this.baseVersion && (this.baseVersion.versionIndex === this.selectedIndex || !this.selectedIndex);
    },
    latestVersionSelected() {
      return this.latestVersion && (this.latestVersion.versionIndex === this.selectedIndex || !this.selectedIndex);
    },
    selectedVersionName() {
      const selectedVersion = this.baseVersionSelected ? this.baseVersion : this.targetVersions[this.selectedIndex];
      return this.versionName(selectedVersion);
    },
  },
  methods: {
    versionName(version) {
      if (this.latestVersion && version.versionIndex === this.latestVersion.versionIndex) {
        return 'latest version';
      }
      if (this.baseVersion && version.versionIndex === this.baseVersion.versionIndex) {
        return this.baseVersion.branchName;
      }
      return `version ${version.versionIndex}`
    },
    isActive(version) {
      if (this.latestVersion && version.versionIndex === this.latestVersion.versionIndex) {
        return true;
      }
      if (this.baseVersion && version.versionIndex === this.baseVersion.versionIndex) {
        return true;
      }
      return version.versionIndex === this.selectedIndex;
    }
  },
};
</script>

<template>
  <span class="dropdown inline mr-version-dropdown">
    <a
      class="dropdown-toggle btn btn-default"
      data-toggle="dropdown"
      aria-expanded="false"
    >
      <span>
        {{ selectedVersionName }}
      </span>
      <Icon
        name="angle-down"
        :size="12"
      />
    </a>
    <div class="dropdown-menu dropdown-select dropdown-menu-selectable">
      <div class="dropdown-content">
        <ul>
          <li
            v-for="version in targetVersions"
          >
            <a
              :class="{ 'is-active': isActive(version) }"
              :href="version.path"
            >
              <div>
                <strong>
                  {{ versionName(version) }}
                  <template v-if="version == baseVersion">
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
                  <template v-if="version.commitsCount">
                    {{ n__(`${version.commitsCount} commit,`, `${version.commitsCount} commits,`, version.commitsCount) }}
                  </template>
                  <time-ago
                    class="js-timeago js-timeago-render"
                    :time="version.createdAt"
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

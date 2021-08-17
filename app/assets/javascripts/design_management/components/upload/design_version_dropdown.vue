<script>
import { GlDropdown, GlDropdownItem, GlSprintf } from '@gitlab/ui';
import defaultAvatarUrl from 'images/no_avatar.png';
import { __, sprintf } from '~/locale';
import TimeAgo from '~/vue_shared/components/time_ago_tooltip.vue';
import allVersionsMixin from '../../mixins/all_versions';
import { findVersionId } from '../../utils/design_management_utils';

export default {
  components: {
    GlDropdown,
    GlDropdownItem,
    GlSprintf,
    TimeAgo,
  },
  mixins: [allVersionsMixin],
  computed: {
    queryVersion() {
      return this.$route.query.version;
    },
    currentVersionIdx() {
      if (!this.queryVersion) return 0;

      const idx = this.allVersions.findIndex(
        (version) => this.findVersionId(version.id) === this.queryVersion,
      );

      // if the currentVersionId isn't a valid version (i.e. not in allVersions)
      // then return the latest version (index 0)
      return idx !== -1 ? idx : 0;
    },
    currentVersionId() {
      if (this.queryVersion) return this.queryVersion;

      const currentVersion = this.allVersions[this.currentVersionIdx];
      return this.findVersionId(currentVersion.id);
    },
    dropdownText() {
      if (this.isLatestVersion) {
        return __('Showing latest version');
      }
      // allVersions is sorted in reverse chronological order (latest first)
      const currentVersionNumber = this.allVersions.length - this.currentVersionIdx;

      return sprintf(__('Showing version #%{versionNumber}'), {
        versionNumber: currentVersionNumber,
      });
    },
  },
  methods: {
    findVersionId,
    routeToVersion(versionId) {
      this.$router.push({
        path: this.$route.path,
        query: { version: this.findVersionId(versionId) },
      });
    },
    versionText(versionId) {
      if (this.findVersionId(versionId) === this.latestVersionId) {
        return __('Version %{versionNumber} (latest)');
      }
      return __('Version %{versionNumber}');
    },
    getAvatarUrl(version) {
      return version?.author?.avatarUrl || defaultAvatarUrl;
    },
  },
};
</script>

<template>
  <gl-dropdown :text="dropdownText" size="small">
    <gl-dropdown-item
      v-for="(version, index) in allVersions"
      :key="version.id"
      :is-check-item="true"
      :is-check-centered="true"
      :is-checked="findVersionId(version.id) === currentVersionId"
      :avatar-url="getAvatarUrl(version)"
      @click="routeToVersion(version.id)"
    >
      <strong>
        <gl-sprintf :message="versionText(version.id)">
          <template #versionNumber>
            {{ allVersions.length - index }}
          </template>
        </gl-sprintf>
      </strong>

      <div v-if="version.author" class="gl-text-gray-600 gl-mt-1">
        <div>{{ version.author.name }}</div>
        <time-ago
          v-if="version.createdAt"
          class="text-1"
          :time="version.createdAt"
          tooltip-placement="bottom"
        />
      </div>
    </gl-dropdown-item>
  </gl-dropdown>
</template>

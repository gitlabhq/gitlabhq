<script>
import { GlSprintf, GlButton } from '@gitlab/ui';
import { s__, n__, __, sprintf } from '~/locale';
import CompareDropdownLayout from '~/diffs/components/compare_dropdown_layout.vue';

export default {
  name: 'CompareVersions',
  components: {
    GlSprintf,
    GlButton,
    CompareDropdownLayout,
  },
  props: {
    sourceVersions: {
      type: Array,
      required: true,
    },
    targetVersions: {
      type: Array,
      required: true,
    },
  },
  computed: {
    formattedSourceVersions() {
      return this.sourceVersions.map((v) => ({
        ...v,
        versionName: this.sourceVersionName(v),
        commitsText: this.formatCommitsText(v.commits_count),
      }));
    },
    selectedSourceVersion() {
      return this.sourceVersions.find((v) => v.selected);
    },
    selectedTargetVersion() {
      return this.targetVersions.find((v) => v.selected);
    },
    selectedTargetIsBranch() {
      return Boolean(this.selectedTargetVersion?.branch);
    },
    formattedTargetVersions() {
      return this.targetVersions.map((v) => {
        if (v.version_index == null) {
          return {
            id: v.id,
            selected: v.selected,
            href: v.href,
            versionName: this.targetVersionName(v),
          };
        }

        return {
          ...v,
          versionName: this.targetVersionName(v),
        };
      });
    },
    isViewingNonLatest() {
      const sourceIsNonLatest = this.selectedSourceVersion && !this.selectedSourceVersion.latest;
      const targetIsNonLatest = this.selectedTargetVersion?.version_index != null;
      return sourceIsNonLatest || targetIsNonLatest;
    },
    latestVersionPath() {
      return this.targetVersions.find((v) => v.version_index == null)?.href;
    },
  },
  methods: {
    sourceVersionName(version) {
      if (version.latest) return s__('MergeRequest|latest version');
      return sprintf(s__('MergeRequest|version %{versionIndex}'), {
        versionIndex: version.version_index,
      });
    },
    targetVersionName(version) {
      if (version.branch) return version.branch;
      return sprintf(s__('MergeRequest|version %{versionIndex}'), {
        versionIndex: version.version_index,
      });
    },
    formatCommitsText(count) {
      return n__('%d commit,', '%d commits,', count);
    },
  },
  i18n: {
    compareMessage: s__(
      'MergeRequest|%{targetStart}Compare%{targetEnd} %{sourceStart}and%{sourceEnd}',
    ),
    showLatestVersion: __('Show latest version'),
  },
};
</script>

<template>
  <div class="gl-max-w-[max-content] gl-flex-1 gl-py-2 @sm/panel:gl-flex @sm/panel:gl-items-center">
    <gl-sprintf :message="$options.i18n.compareMessage">
      <template #target="{ content }">
        <span class="gl-inline-flex gl-items-center gl-whitespace-nowrap">
          {{ content }}
          <compare-dropdown-layout
            :versions="formattedTargetVersions"
            :truncate="selectedTargetIsBranch"
            class="mr-version-compare-dropdown gl-mx-1"
            :class="{
              'gl-min-w-min !gl-max-w-[300px] gl-flex-1': selectedTargetIsBranch,
            }"
            data-testid="target-version-dropdown"
          />
        </span>
      </template>
      <template #source="{ content }">
        <span class="gl-inline-flex gl-items-center gl-whitespace-nowrap">
          {{ content }}
          <compare-dropdown-layout
            :versions="formattedSourceVersions"
            class="mr-version-dropdown gl-mx-1"
            data-testid="source-version-dropdown"
          />
        </span>
      </template>
    </gl-sprintf>
    <gl-button
      v-if="isViewingNonLatest"
      :href="latestVersionPath"
      size="small"
      class="gl-ml-3 gl-shrink-0"
      data-testid="show-latest-version-button"
    >
      {{ $options.i18n.showLatestVersion }}
    </gl-button>
  </div>
</template>

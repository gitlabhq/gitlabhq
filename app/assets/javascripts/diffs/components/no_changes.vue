<script>
import { GlSprintf, GlEmptyState } from '@gitlab/ui';
// eslint-disable-next-line no-restricted-imports
import { mapGetters } from 'vuex';
import { s__, __ } from '~/locale';

export default {
  i18n: {
    title: s__('MergeRequest|There are no changes yet'),
    message: __('No changes between %{source} and %{target}'),
    buttonText: __('Create commit'),
  },
  components: {
    GlSprintf,
    GlEmptyState,
  },
  props: {
    changesEmptyStateIllustration: {
      type: String,
      required: true,
    },
  },
  computed: {
    ...mapGetters('diffs', [
      'diffCompareDropdownTargetVersions',
      'diffCompareDropdownSourceVersions',
    ]),
    ...mapGetters(['getNoteableData']),
    selectedSourceVersion() {
      return this.diffCompareDropdownSourceVersions.find((x) => x.selected);
    },
    sourceName() {
      if (!this.selectedSourceVersion || this.selectedSourceVersion.isLatestVersion) {
        return this.getNoteableData.source_branch;
      }

      return this.selectedSourceVersion.versionName;
    },
    selectedTargetVersion() {
      return this.diffCompareDropdownTargetVersions.find((x) => x.selected);
    },
    targetName() {
      if (!this.selectedTargetVersion || this.selectedTargetVersion.version_index < 0) {
        return this.getNoteableData.target_branch;
      }

      return this.selectedTargetVersion.versionName || '';
    },
  },
};
</script>

<template>
  <gl-empty-state
    :title="$options.i18n.title"
    :svg-path="changesEmptyStateIllustration"
    :primary-button-text="$options.i18n.buttonText"
    :primary-button-link="getNoteableData.new_blob_path"
  >
    <template #description>
      <span data-testid="no-changes-message">
        <gl-sprintf :message="$options.i18n.message">
          <template #source>
            <span class="ref-name">{{ sourceName }}</span>
          </template>
          <template #target>
            <span class="ref-name">{{ targetName }}</span>
          </template>
        </gl-sprintf>
      </span>
    </template>
  </gl-empty-state>
</template>

<script>
import { GlButton, GlSprintf } from '@gitlab/ui';
import { mapGetters } from 'vuex';

export default {
  components: {
    GlButton,
    GlSprintf,
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
  <div class="row empty-state">
    <div class="col-12">
      <div class="svg-content svg-250"><img :src="changesEmptyStateIllustration" /></div>
    </div>
    <div class="col-12">
      <div class="text-content text-center">
        <div data-testid="no-changes-message">
          <gl-sprintf :message="__('No changes between %{source} and %{target}')">
            <template #source>
              <span class="ref-name">{{ sourceName }}</span>
            </template>
            <template #target>
              <span class="ref-name">{{ targetName }}</span>
            </template>
          </gl-sprintf>
        </div>
        <div class="text-center">
          <gl-button :href="getNoteableData.new_blob_path" variant="success" category="primary">{{
            __('Create commit')
          }}</gl-button>
        </div>
      </div>
    </div>
  </div>
</template>

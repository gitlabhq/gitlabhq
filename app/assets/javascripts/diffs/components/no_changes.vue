<script>
import { mapGetters } from 'vuex';
import { GlButton, GlSprintf } from '@gitlab/ui';

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
    ...mapGetters(['getNoteableData']),
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
        <gl-sprintf :message="__('No changes between %{sourceBranch} and %{targetBranch}')">
          <template #sourceBranch>
            <span class="ref-name">{{ getNoteableData.source_branch }}</span>
          </template>
          <template #targetBranch>
            <span class="ref-name">{{ getNoteableData.target_branch }}</span>
          </template>
        </gl-sprintf>
        <div class="text-center">
          <gl-button :href="getNoteableData.new_blob_path" variant="success" category="primary">{{
            __('Create commit')
          }}</gl-button>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { mapGetters } from 'vuex';
import { escape } from 'lodash';
import { GlButton } from '@gitlab/ui';
import { __, sprintf } from '~/locale';

export default {
  components: {
    GlButton,
  },
  props: {
    changesEmptyStateIllustration: {
      type: String,
      required: true,
    },
  },
  computed: {
    ...mapGetters(['getNoteableData']),
    emptyStateText() {
      return sprintf(
        __(
          'No changes between %{ref_start}%{source_branch}%{ref_end} and %{ref_start}%{target_branch}%{ref_end}',
        ),
        {
          ref_start: '<span class="ref-name">',
          ref_end: '</span>',
          source_branch: escape(this.getNoteableData.source_branch),
          target_branch: escape(this.getNoteableData.target_branch),
        },
        false,
      );
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
        <span v-html="emptyStateText"></span>
        <div class="text-center">
          <gl-button :href="getNoteableData.new_blob_path" variant="success" category="primary">{{
            __('Create commit')
          }}</gl-button>
        </div>
      </div>
    </div>
  </div>
</template>

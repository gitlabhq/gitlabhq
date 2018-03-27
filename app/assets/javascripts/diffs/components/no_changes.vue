<script>
import { mapState, mapActions } from 'vuex';
import emptyImage from '~/../../views/shared/icons/_mr_widget_empty_state.svg';

export default {
  data() {
    return {
      emptyImage,
    };
  },
  computed: {
    ...mapState({
      sourceBranch: state => state.notes.noteableData.source_branch,
      targetBranch: state => state.notes.noteableData.target_branch,
      newBlobPath: state => state.notes.noteableData.new_blob_path,
    }),
  },
};
</script>

<template>
  <div
    class="row empty-state nothing-here-block"
  >
    <div class="col-xs-12">
      <div class="svg-content">
        <span
          v-html="emptyImage"
        ></span>
      </div>
    </div>
    <div class="col-xs-12">
      <p class="text-content text-center">
        No changes between
        <span class="ref-name">{{ sourceBranch }}</span>
        and
        <span class="ref-name">{{ targetBranch }}</span>
        <div class="text-center">
          <a
            :href="newBlobPath"
            class="btn btn-save"
          >
            {{ __('Create commit') }}
          </a>
        </div>
      </p>
    </div>
  </div>
</template>

<script>
export default {
  props: {
    editPath: {
      type: String,
      required: false,
      default: '',
    },
  },
}

/*
Edit button
 - if not on a branch. "You can only edit files when you are on a branch"
 - if on branch, "Edit"
 - else "Fork"
*/
</script>

<template>
  <span>
    <a
      v-if="editPath"
      :href="editPath"
      class="btn btn-default js-edit-blob"
    >
      Edit
    </a>

    <div class="js-file-fork-suggestion-section file-fork-suggestion hidden">
      <span class="file-fork-suggestion-note">
        You're not allowed to <span class="js-file-fork-suggestion-section-action">edit</span>
        files in this project directly. Please fork this project,
        make your changes there, and submit a merge request.
      </span>
      <button
        class="js-fork-suggestion-button btn btn-grouped btn-inverted btn-success"
      >
        Fork
      </button>
      <button
        class="js-cancel-fork-suggestion-button btn btn-grouped"
        type="button"
      >
        Cancel
      </button>
    </div>
  </span>
</template>

<script>
import Store from '../stores/repo_store';
import RepoMixin from '../mixins/repo_mixin';

export default {
  data: () => Store,
  mixins: [RepoMixin],
  computed: {
    buttonLabel() {
      return this.editMode ? this.__('Cancel edit') : this.__('Edit');
    },

    showButton() {
      return this.isCommitable &&
        !this.activeFile.render_error &&
        !this.binary &&
        this.openedFiles.length;
    },
  },
  methods: {
    editCancelClicked() {
      if (this.changedFiles.length) {
        this.dialog.open = true;
        return;
      }
      this.editMode = !this.editMode;
      Store.toggleBlobView();
    },
    toggleProjectRefsForm() {
      $('.project-refs-form').toggleClass('disabled', this.editMode);
      $('.js-tree-ref-target-holder').toggle(this.editMode);
    },
  },

  watch: {
    editMode() {
      this.toggleProjectRefsForm();
    },
  },
};
</script>

<template>
<button
  v-if="showButton"
  class="btn btn-default"
  type="button"
  @click.prevent="editCancelClicked">
  <i
    v-if="!editMode"
    class="fa fa-pencil"
    aria-hidden="true">
  </i>
  <span>
    {{buttonLabel}}
  </span>
</button>
</template>

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
      return this.isCommitable && !this.activeFile.render_error && !this.binary;
    }
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
  },

  watch: {
    editMode() {
      $('.project-refs-form').toggleClass('disabled', this.editMode);
      $('.js-tree-ref-target-holder').toggle(this.editMode);
    },
  },
};
</script>

<template>
<button class="btn btn-default" type="button" @click.prevent="editCancelClicked" v-if="showButton">
  <i class="fa fa-pencil" v-if="!editMode"></i>
  <span>{{buttonLabel}}</span>
</button>
</template>

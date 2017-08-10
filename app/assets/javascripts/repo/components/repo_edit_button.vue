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
      return this.isCommitable && !this.activeFile.render_error;
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
      $('.fa-long-arrow-right, .project-refs-target-form').toggle(this.editMode);
    },
  },
};
</script>

<template>
<button class="btn btn-default" type="button" @click.prevent="editCancelClicked" v-if="showButton" :disabled="binary">
  <i class="fa fa-pencil" v-if="!editMode"></i>
  <span>{{buttonLabel}}</span>
</button>
</template>

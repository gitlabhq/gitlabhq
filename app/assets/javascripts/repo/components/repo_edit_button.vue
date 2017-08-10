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
<button class="btn btn-default" @click.prevent="editCancelClicked" v-cloak v-if="isCommitable && !activeFile.render_error" :disabled="binary">
  <i class="fa fa-pencil" v-if="!editMode"></i>
  <span>{{buttonLabel}}</span>
</button>
</template>

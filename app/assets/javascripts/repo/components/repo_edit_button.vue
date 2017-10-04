<script>
import Store from '../stores/repo_store';
import RepoMixin from '../mixins/repo_mixin';
import PopupDialog from '../../vue_shared/components/popup_dialog.vue';

export default {
  data: () => Store,
  mixins: [RepoMixin],
  components: {
    PopupDialog,
  },
  computed: {
    buttonLabel() {
      return this.editMode ? this.__('Cancel edit') : this.__('Edit');
    },

    showButton() {
      return this.signedIn &&
        !this.activeFile.render_error &&
        !this.binary &&
        this.openedFiles.length;
    },
  },
  methods: {
    editCancelClicked() {
      console.log('canCommit',typeof this.canCommit);
      if(!this.canCommit) {
        console.log('noooooo')
        this.showForkDialog = true;
        return;
      }
      if(this.changedFiles.length) {
        this.dialog.open = true;
        return;
      }
      this.editMode = !this.editMode;
      Store.toggleBlobView();
    },

    forkRepoSubmit() {

    },
  },
};
</script>

<template>
<div>
  <popup-dialog
    v-if="showForkDialog"
    :primary-button-label="__('Create New Branch')"
    kind="primary"
    :title="__('Branch has changed')"
    :body="__('This branch has changed since your started editing. Would you like to create a new branch?')"
    @submit="forkRepoSubmit"
  />
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
</div>
</template>

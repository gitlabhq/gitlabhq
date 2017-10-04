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
      const forkForm = document.createElement('FORM');
      const csrfParam = document
        .querySelector('meta[name="csrf-param"]')
        .content;
      console.log(csrfParam);
      const authToken = document
        .querySelector('meta[name="csrf-token"]')
        .content;
      forkForm.name = 'fork-repo';
      forkForm.method = 'POST';
      let input = document.createElement('INPUT');
      input.type = 'HIDDEN';
      input.name = csrfParam;
      input.value = authToken;
      forkForm.appendChild(input);
      forkForm.action = Store.forkUrl;
      document.body.appendChild(forkForm);
      forkForm.submit();
    },
  },
};
</script>

<template>
<div>
  <popup-dialog
    v-if="showForkDialog"
    :primary-button-label="__('Create Fork')"
    kind="primary"
    :title="__('Create a Fork')"
    :body="__('You are not allowed to edit files in this project directly. Please fork this project, make your changes there, and submit a merge request.')"
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

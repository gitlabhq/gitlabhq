<script>
  import { __ } from '../../../locale';
  import popupDialog from '../../../vue_shared/components/popup_dialog.vue';
  import RepoStore from '../../stores/repo_store';
  import RepoHelper from '../../helpers/repo_helper';

  export default {
    props: {
      type: {
        type: String,
        required: true,
      },
    },
    data() {
      return {
        entryName: '',
      };
    },
    components: {
      popupDialog,
    },
    methods: {
      createEntryInStore() {
        if (this.entryName === '') return;

        const fileName = this.type === 'tree' ? '.gitkeep' : this.entryName;
        let tree = null;

        if (this.type === 'tree') {
          tree = RepoHelper.serializeTree({
            name: this.entryName,
            path: this.entryName,
            tempFile: true,
          });
          RepoStore.files.push(tree);

          RepoHelper.setDirectoryOpen(tree, tree.name);
        }

        const file = RepoHelper.serializeBlob({
          name: fileName,
          path: tree ? `${tree}/${fileName}` : fileName,
          tempFile: true,
        });

        if (tree) {
          RepoStore.addFilesToDirectory(tree, RepoStore.files, [file]);
        } else {
          RepoStore.addFilesToDirectory(tree, RepoStore.files, [...RepoStore.files, file]);
        }

        RepoHelper.setFile(file, file);
        RepoStore.editMode = true;
        RepoStore.toggleBlobView();

        this.toggleModalOpen();
      },
      toggleModalOpen() {
        this.$emit('toggle');
      },
    },
    computed: {
      modalTitle() {
        if (this.type === 'tree') {
          return __('Create new directory');
        }

        return __('Create new file');
      },
      buttonLabel() {
        if (this.type === 'tree') {
          return __('Create directory');
        }

        return __('Create file');
      },
      formLabelName() {
        if (this.type === 'tree') {
          return __('Directory name');
        }

        return __('File name');
      },
    },
  };
</script>

<template>
  <popup-dialog
    :title="modalTitle"
    :primary-button-label="buttonLabel"
    kind="success"
    @toggle="toggleModalOpen"
    @submit="createEntryInStore"
  >
    <form
      class="form-horizontal"
      slot="body"
      @submit.prevent="createEntryInStore"
    >
      <fieldset class="form-group append-bottom-0">
        <label class="label-light col-sm-3">
          {{ formLabelName }}
        </label>
        <div class="col-sm-9">
          <input
            type="text"
            class="form-control"
            v-model="entryName"
          />
        </div>
      </fieldset>
    </form>
  </popup-dialog>
</template>

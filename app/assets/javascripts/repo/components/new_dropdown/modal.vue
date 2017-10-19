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
        entryName: RepoStore.path !== '' ? `${RepoStore.path}/` : '',
      };
    },
    components: {
      popupDialog,
    },
    methods: {
      createEntryInStore() {
        const originalPath = RepoStore.path;
        let entryName = this.entryName;

        if (entryName.indexOf(`${RepoStore.path}/`) !== 0) {
          RepoStore.path = '';
        } else {
          entryName = entryName.replace(`${RepoStore.path}/`, '');
        }

        if (entryName === '') return;

        const fileName = this.type === 'tree' ? '.gitkeep' : entryName;
        let tree = RepoStore;

        if (this.type === 'tree') {
          const dirNames = entryName.split('/');

          dirNames.forEach((dirName) => {
            if (dirName === '') return;

            tree = RepoHelper.findOrCreateEntry('tree', tree, dirName).entry;
          });
        }

        if ((this.type === 'tree' && tree.tempFile) || this.type === 'blob') {
          const file = RepoHelper.findOrCreateEntry('blob', tree, fileName);

          if (!file.exists) {
            RepoHelper.setFile(file.entry, file.entry);

            RepoStore.editMode = true;
            RepoStore.currentBlobView = 'repo-editor';
          }
        }

        this.toggleModalOpen();

        RepoStore.path = originalPath;
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
    mounted() {
      this.$refs.fieldName.focus();
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
            ref="fieldName"
          />
        </div>
      </fieldset>
    </form>
  </popup-dialog>
</template>

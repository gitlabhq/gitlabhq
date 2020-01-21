<script>
import $ from 'jquery';
import { mapActions, mapState, mapGetters } from 'vuex';
import flash from '~/flash';
import { __, sprintf, s__ } from '~/locale';
import DeprecatedModal2 from '~/vue_shared/components/deprecated_modal_2.vue';
import { modalTypes } from '../../constants';

export default {
  components: {
    GlModal: DeprecatedModal2,
  },
  data() {
    return {
      name: '',
    };
  },
  computed: {
    ...mapState(['entries', 'entryModal']),
    ...mapGetters('fileTemplates', ['templateTypes']),
    entryName: {
      get() {
        const entryPath = this.entryModal.entry.path;

        if (this.entryModal.type === modalTypes.rename) {
          return this.name || entryPath;
        }

        return this.name || (entryPath ? `${entryPath}/` : '');
      },
      set(val) {
        this.name = val.trim();
      },
    },
    modalTitle() {
      if (this.entryModal.type === modalTypes.tree) {
        return __('Create new directory');
      } else if (this.entryModal.type === modalTypes.rename) {
        return this.entryModal.entry.type === modalTypes.tree
          ? __('Rename folder')
          : __('Rename file');
      }

      return __('Create new file');
    },
    buttonLabel() {
      if (this.entryModal.type === modalTypes.tree) {
        return __('Create directory');
      } else if (this.entryModal.type === modalTypes.rename) {
        return this.entryModal.entry.type === modalTypes.tree
          ? __('Rename folder')
          : __('Rename file');
      }

      return __('Create file');
    },
    isCreatingNewFile() {
      return this.entryModal.type === 'blob';
    },
    placeholder() {
      return this.isCreatingNewFile ? 'dir/file_name' : 'dir/';
    },
  },
  methods: {
    ...mapActions(['createTempEntry', 'renameEntry']),
    submitForm() {
      if (this.entryModal.type === modalTypes.rename) {
        if (this.entries[this.entryName] && !this.entries[this.entryName].deleted) {
          flash(
            sprintf(s__('The name "%{name}" is already taken in this directory.'), {
              name: this.entryName,
            }),
            'alert',
            document,
            null,
            false,
            true,
          );
        } else {
          let parentPath = this.entryName.split('/');
          const entryName = parentPath.pop();
          parentPath = parentPath.join('/');

          this.renameEntry({
            path: this.entryModal.entry.path,
            name: entryName,
            parentPath,
          });
        }
      } else {
        this.createTempEntry({
          name: this.name,
          type: this.entryModal.type,
        });
      }
    },
    createFromTemplate(template) {
      this.createTempEntry({
        name: template.name,
        type: this.entryModal.type,
      });

      $('#ide-new-entry').modal('toggle');
    },
    focusInput() {
      const name = this.entries[this.entryName] ? this.entries[this.entryName].name : null;
      const inputValue = this.$refs.fieldName.value;

      this.$refs.fieldName.focus();

      if (name) {
        this.$refs.fieldName.setSelectionRange(inputValue.indexOf(name), inputValue.length);
      }
    },
    closedModal() {
      this.name = '';
    },
  },
};
</script>

<template>
  <gl-modal
    id="ide-new-entry"
    class="qa-new-file-modal"
    :header-title-text="modalTitle"
    :footer-primary-button-text="buttonLabel"
    footer-primary-button-variant="success"
    modal-size="lg"
    @submit="submitForm"
    @open="focusInput"
    @closed="closedModal"
  >
    <div class="form-group row">
      <label class="label-bold col-form-label col-sm-2"> {{ __('Name') }} </label>
      <div class="col-sm-10">
        <input
          ref="fieldName"
          v-model="entryName"
          type="text"
          class="form-control qa-full-file-path"
          :placeholder="placeholder"
        />
        <ul
          v-if="isCreatingNewFile"
          class="file-templates prepend-top-default list-inline qa-template-list"
        >
          <li v-for="(template, index) in templateTypes" :key="index" class="list-inline-item">
            <button
              type="button"
              class="btn btn-missing p-1 pr-2 pl-2"
              @click="createFromTemplate(template)"
            >
              {{ template.name }}
            </button>
          </li>
        </ul>
      </div>
    </div>
  </gl-modal>
</template>

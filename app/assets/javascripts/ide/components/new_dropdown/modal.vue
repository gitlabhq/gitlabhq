<script>
import { mapActions, mapState, mapGetters } from 'vuex';
import flash from '~/flash';
import { __, sprintf, s__ } from '~/locale';
import { GlModal } from '@gitlab/ui';
import { modalTypes } from '../../constants';

export default {
  components: {
    GlModal,
  },
  data() {
    return {
      name: '',
      type: modalTypes.blob,
      path: '',
    };
  },
  computed: {
    ...mapState(['entries']),
    ...mapGetters('fileTemplates', ['templateTypes']),
    entryName: {
      get() {
        if (this.type === modalTypes.rename) {
          return this.name || this.path;
        }

        return this.name || (this.path ? `${this.path}/` : '');
      },
      set(val) {
        this.name = val.trim();
      },
    },
    modalTitle() {
      const entry = this.entries[this.path];

      if (this.type === modalTypes.tree) {
        return __('Create new directory');
      } else if (this.type === modalTypes.rename) {
        return entry.type === modalTypes.tree ? __('Rename folder') : __('Rename file');
      }

      return __('Create new file');
    },
    buttonLabel() {
      const entry = this.entries[this.path];

      if (this.type === modalTypes.tree) {
        return __('Create directory');
      } else if (this.type === modalTypes.rename) {
        return entry.type === modalTypes.tree ? __('Rename folder') : __('Rename file');
      }

      return __('Create file');
    },
    isCreatingNewFile() {
      return this.type === modalTypes.blob;
    },
    placeholder() {
      return this.isCreatingNewFile ? 'dir/file_name' : 'dir/';
    },
  },
  methods: {
    ...mapActions(['createTempEntry', 'renameEntry']),
    submitForm() {
      if (this.type === modalTypes.rename) {
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
            path: this.path,
            name: entryName,
            parentPath,
          });
        }
      } else {
        this.createTempEntry({
          name: this.name,
          type: this.type,
        });
      }
    },
    createFromTemplate(template) {
      this.createTempEntry({
        name: template.name,
        type: this.type,
      });

      this.$refs.modal.toggle();
    },
    focusInput() {
      const name = this.entries[this.entryName] ? this.entries[this.entryName].name : null;
      const inputValue = this.$refs.fieldName.value;

      this.$refs.fieldName.focus();

      if (name) {
        this.$refs.fieldName.setSelectionRange(inputValue.indexOf(name), inputValue.length);
      }
    },
    resetData() {
      this.name = '';
      this.path = '';
      this.type = modalTypes.blob;
    },
    open(type = modalTypes.blob, path = '') {
      this.type = type;
      this.path = path;
      this.$refs.modal.show();

      // wait for modal to show first
      this.$nextTick(() => {
        this.focusInput();
      });
    },
    close() {
      this.$refs.modal.hide();
    },
  },
};
</script>

<template>
  <gl-modal
    ref="modal"
    modal-id="ide-new-entry"
    modal-class="qa-new-file-modal"
    :title="modalTitle"
    :ok-title="buttonLabel"
    ok-variant="success"
    size="lg"
    @ok="submitForm"
    @hide="resetData"
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

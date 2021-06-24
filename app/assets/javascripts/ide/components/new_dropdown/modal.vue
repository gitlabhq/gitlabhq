<script>
import { GlModal, GlButton } from '@gitlab/ui';
import { mapActions, mapState, mapGetters } from 'vuex';
import createFlash from '~/flash';
import { __, sprintf, s__ } from '~/locale';
import { modalTypes } from '../../constants';
import { trimPathComponents, getPathParent } from '../../utils';

export default {
  components: {
    GlModal,
    GlButton,
  },
  data() {
    return {
      entryName: '',
      modalType: modalTypes.blob,
      path: '',
    };
  },
  computed: {
    ...mapState(['entries']),
    ...mapGetters('fileTemplates', ['templateTypes']),
    modalTitle() {
      const entry = this.entries[this.path];

      if (this.modalType === modalTypes.tree) {
        return __('Create new directory');
      } else if (this.modalType === modalTypes.rename) {
        return entry.type === modalTypes.tree ? __('Rename folder') : __('Rename file');
      }

      return __('Create new file');
    },
    buttonLabel() {
      const entry = this.entries[this.path];

      if (this.modalType === modalTypes.tree) {
        return __('Create directory');
      } else if (this.modalType === modalTypes.rename) {
        return entry.type === modalTypes.tree ? __('Rename folder') : __('Rename file');
      }

      return __('Create file');
    },
    isCreatingNewFile() {
      return this.modalType === modalTypes.blob;
    },
    placeholder() {
      return this.isCreatingNewFile ? 'dir/file_name' : 'dir/';
    },
  },
  methods: {
    ...mapActions(['createTempEntry', 'renameEntry']),
    submitForm() {
      this.entryName = trimPathComponents(this.entryName);

      if (this.modalType === modalTypes.rename) {
        if (this.entries[this.entryName] && !this.entries[this.entryName].deleted) {
          createFlash({
            message: sprintf(s__('The name "%{name}" is already taken in this directory.'), {
              name: this.entryName,
            }),
            fadeTransition: false,
            addBodyClass: true,
          });
        } else {
          let parentPath = this.entryName.split('/');
          const name = parentPath.pop();
          parentPath = parentPath.join('/');

          this.renameEntry({
            path: this.path,
            name,
            parentPath,
          });
        }
      } else {
        this.createTempEntry({
          name: this.entryName,
          type: this.modalType,
        });
      }
    },
    createFromTemplate(template) {
      const parent = getPathParent(this.entryName);
      const name = parent ? `${parent}/${template.name}` : template.name;
      this.createTempEntry({
        name,
        type: this.modalType,
      });

      this.$refs.modal.toggle();
    },
    focusInput() {
      const name = this.entries[this.entryName]?.name;
      const inputValue = this.$refs.fieldName.value;

      this.$refs.fieldName.focus();

      if (name) {
        this.$refs.fieldName.setSelectionRange(inputValue.indexOf(name), inputValue.length);
      }
    },
    resetData() {
      this.entryName = '';
      this.path = '';
      this.modalType = modalTypes.blob;
    },
    open(type = modalTypes.blob, path = '') {
      this.modalType = type;
      this.path = path;

      if (this.modalType === modalTypes.rename) {
        this.entryName = path;
      } else {
        this.entryName = path ? `${path}/` : '';
      }

      this.$refs.modal.show();

      // wait for modal to show first
      this.$nextTick(() => this.focusInput());
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
    data-qa-selector="new_file_modal"
    data-testid="ide-new-entry"
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
          v-model.trim="entryName"
          type="text"
          class="form-control"
          data-testid="file-name-field"
          data-qa-selector="file_name_field"
          :placeholder="placeholder"
        />
        <ul v-if="isCreatingNewFile" class="file-templates gl-mt-3 list-inline qa-template-list">
          <li v-for="(template, index) in templateTypes" :key="index" class="list-inline-item">
            <gl-button
              variant="dashed"
              category="secondary"
              class="p-1 pr-2 pl-2"
              @click="createFromTemplate(template)"
            >
              {{ template.name }}
            </gl-button>
          </li>
        </ul>
      </div>
    </div>
  </gl-modal>
</template>

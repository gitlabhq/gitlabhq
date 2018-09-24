<script>
import $ from 'jquery';
import { __ } from '~/locale';
import { mapActions, mapState, mapGetters } from 'vuex';
import GlModal from '~/vue_shared/components/gl_modal.vue';
import { modalTypes } from '../../constants';

export default {
  components: {
    GlModal,
  },
  data() {
    return {
      name: '',
    };
  },
  computed: {
    ...mapState(['entryModal']),
    ...mapGetters('fileTemplates', ['templateTypes']),
    entryName: {
      get() {
        if (this.entryModal.type === modalTypes.rename) {
          return this.name || this.entryModal.entry.name;
        }

        return this.name || (this.entryModal.path !== '' ? `${this.entryModal.path}/` : '');
      },
      set(val) {
        this.name = val;
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
    isCreatingNew() {
      return this.entryModal.type !== modalTypes.rename;
    },
  },
  methods: {
    ...mapActions(['createTempEntry', 'renameEntry']),
    submitForm() {
      if (this.entryModal.type === modalTypes.rename) {
        this.renameEntry({
          path: this.entryModal.entry.path,
          name: this.entryName,
        });
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
      this.$refs.fieldName.focus();
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
    :header-title-text="modalTitle"
    :footer-primary-button-text="buttonLabel"
    footer-primary-button-variant="success"
    modal-size="lg"
    @submit="submitForm"
    @open="focusInput"
    @closed="closedModal"
  >
    <div
      class="form-group row"
    >
      <label class="label-bold col-form-label col-sm-2">
        {{ __('Name') }}
      </label>
      <div class="col-sm-10">
        <input
          ref="fieldName"
          v-model="entryName"
          type="text"
          class="form-control"
          placeholder="/dir/file_name"
        />
        <ul
          v-if="isCreatingNew"
          class="prepend-top-default list-inline"
        >
          <li
            v-for="(template, index) in templateTypes"
            :key="index"
            class="list-inline-item"
          >
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

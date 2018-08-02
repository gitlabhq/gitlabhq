<script>
import { __ } from '~/locale';
import { mapActions, mapState } from 'vuex';
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
        return this.entryModal.entry.type === modalTypes.tree ? __('Rename folder') : __('Rename file');
      }

      return __('Create new file');
    },
    buttonLabel() {
      if (this.entryModal.type === modalTypes.tree) {
        return __('Create directory');
      } else if (this.entryModal.type === modalTypes.rename) {
        return this.entryModal.entry.type === modalTypes.tree ? __('Rename folder') : __('Rename file');
      }

      return __('Create file');
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
    @submit="submitForm"
    @open="focusInput"
    @closed="closedModal"
  >
    <div
      class="form-group row"
    >
      <label class="label-bold col-form-label col-sm-3">
        {{ __('Name') }}
      </label>
      <div class="col-sm-9">
        <input
          ref="fieldName"
          v-model="entryName"
          type="text"
          class="form-control"
        />
      </div>
    </div>
  </gl-modal>
</template>

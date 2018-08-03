<script>
import { __ } from '~/locale';
import { mapActions, mapState } from 'vuex';
import GlModal from '~/vue_shared/components/gl_modal.vue';

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
    ...mapState(['newEntryModal']),
    entryName: {
      get() {
        return this.name || (this.newEntryModal.path !== '' ? `${this.newEntryModal.path}/` : '');
      },
      set(val) {
        this.name = val;
      },
    },
    modalTitle() {
      if (this.newEntryModal.type === 'tree') {
        return __('Create new directory');
      }

      return __('Create new file');
    },
    buttonLabel() {
      if (this.newEntryModal.type === 'tree') {
        return __('Create directory');
      }

      return __('Create file');
    },
  },
  methods: {
    ...mapActions(['createTempEntry']),
    createEntryInStore() {
      this.createTempEntry({
        name: this.name,
        type: this.newEntryModal.type,
      });
    },
    focusInput() {
      setTimeout(() => {
        this.$refs.fieldName.focus();
      });
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
    @submit="createEntryInStore"
    @open="focusInput"
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

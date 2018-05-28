<script>
import { __ } from '~/locale';
import DeprecatedModal from '~/vue_shared/components/deprecated_modal.vue';

export default {
  components: {
    DeprecatedModal,
  },
  props: {
    branchId: {
      type: String,
      required: true,
    },
    type: {
      type: String,
      required: true,
    },
    path: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      entryName: this.path !== '' ? `${this.path}/` : '',
    };
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
  },
  mounted() {
    this.$refs.fieldName.focus();
  },
  methods: {
    createEntryInStore() {
      this.$emit('create', {
        branchId: this.branchId,
        name: this.entryName,
        type: this.type,
      });

      this.hideModal();
    },
    hideModal() {
      this.$emit('hide');
    },
  },
};
</script>

<template>
  <deprecated-modal
    :title="modalTitle"
    :primary-button-label="buttonLabel"
    kind="success"
    @cancel="hideModal"
    @submit="createEntryInStore"
  >
    <form
      slot="body"
      @submit.prevent="createEntryInStore"
      class="form-group row append-bottom-0"
    >
      <fieldset class="form-group append-bottom-0">
        <label class="label-light col-form-label col-sm-3 ide-new-modal-label">
          {{ __('Name') }}
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
  </deprecated-modal>
</template>

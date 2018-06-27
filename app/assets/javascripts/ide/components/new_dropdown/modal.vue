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
      class="form-group row"
      @submit.prevent="createEntryInStore"
    >
      <label class="label-light col-form-label col-sm-3">
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
    </form>
  </deprecated-modal>
</template>

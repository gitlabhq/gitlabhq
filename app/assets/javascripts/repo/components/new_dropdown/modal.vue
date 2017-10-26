<script>
  import { mapActions, mapState } from 'vuex';
  import { __ } from '../../../locale';
  import popupDialog from '../../../vue_shared/components/popup_dialog.vue';

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
      ...mapActions([
        'createTempEntry',
      ]),
      createEntryInStore() {
        this.createTempEntry({
          name: this.entryName,
          type: this.type,
        });

        this.toggleModalOpen();
      },
      toggleModalOpen() {
        this.$emit('toggle');
      },
    },
    computed: {
      ...mapState([
        'path',
      ]),
      name: {
        get() {
          return this.path !== '' ? `${this.path}/${this.entryName}` : this.entryName;
        },
        set(newVal) {
          this.entryName = newVal.replace(`${this.path}/`, '');
        },
      },
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
            v-model="name"
            ref="fieldName"
          />
        </div>
      </fieldset>
    </form>
  </popup-dialog>
</template>

<script>
  import { mapActions } from 'vuex';
  import { __ } from '../../../locale';
  import popupDialog from '../../../vue_shared/components/popup_dialog.vue';

  export default {
    props: {
<<<<<<< HEAD
      path: {
=======
      type: {
>>>>>>> 6306e797acca358c79c120e5b12c29a5ec604571
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
    components: {
      popupDialog,
    },
    methods: {
      ...mapActions([
        'createTempEntry',
      ]),
      createEntryInStore() {
<<<<<<< HEAD
<<<<<<< HEAD
        eventHub.$emit('createNewEntry', {
          name: this.entryName,
=======
        this.createTempEntry({
          name: this.entryName.replace(new RegExp(`^${this.path}/`), ''),
>>>>>>> 6306e797acca358c79c120e5b12c29a5ec604571
          type: this.type,
        });
<<<<<<< HEAD
=======
        this.createTempEntry({
          name: this.entryName.replace(new RegExp(`^${this.path}/`), ''),
          type: this.type,
        });

        this.toggleModalOpen();
>>>>>>> e24d1890aea9c550e02d9145f50e8e1ae153a3a3
=======

        this.toggleModalOpen();
>>>>>>> 6306e797acca358c79c120e5b12c29a5ec604571
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

<script>
import { GlButton, GlForm } from '@gitlab/ui';
import csrf from '~/lib/utils/csrf';
import { s__, __ } from '~/locale';
import DeleteModal from './delete_modal.vue';

export default {
  name: 'GroupDeleteButton',
  components: {
    GlButton,
    GlForm,
    DeleteModal,
  },
  props: {
    formPath: {
      type: String,
      required: true,
    },
    confirmPhrase: {
      type: String,
      required: true,
    },
    fullName: {
      type: String,
      required: true,
    },
    subgroupsCount: {
      type: Number,
      required: false,
      default: null,
    },
    projectsCount: {
      type: Number,
      required: false,
      default: null,
    },
    markedForDeletion: {
      type: Boolean,
      required: true,
    },
    permanentDeletionDate: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      isModalVisible: false,
    };
  },
  computed: {
    csrfToken() {
      return csrf.token;
    },
    buttonText() {
      return this.markedForDeletion ? s__('GroupSettings|Delete permanently') : __('Delete');
    },
  },
  methods: {
    submitForm() {
      this.$refs.form.$el.submit();
    },
    onButtonClick() {
      this.isModalVisible = true;
    },
  },
};
</script>

<template>
  <gl-form ref="form" :action="formPath" method="post">
    <input type="hidden" name="_method" value="delete" />
    <input :value="csrfToken" type="hidden" name="authenticity_token" />
    <input v-if="markedForDeletion" type="hidden" name="permanently_remove" value="true" />

    <delete-modal
      v-model="isModalVisible"
      :confirm-phrase="confirmPhrase"
      :full-name="fullName"
      :subgroups-count="subgroupsCount"
      :projects-count="projectsCount"
      :marked-for-deletion="markedForDeletion"
      :permanent-deletion-date="permanentDeletionDate"
      @primary="submitForm"
    />

    <gl-button
      category="primary"
      variant="danger"
      data-testid="delete-button"
      @click="onButtonClick"
      >{{ buttonText }}</gl-button
    >
  </gl-form>
</template>

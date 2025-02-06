<script>
import { GlButton, GlForm } from '@gitlab/ui';
import csrf from '~/lib/utils/csrf';
import { __ } from '~/locale';
import DeleteModal from './delete_modal.vue';

export default {
  components: {
    GlButton,
    GlForm,
    DeleteModal,
  },
  props: {
    confirmPhrase: {
      type: String,
      required: true,
    },
    nameWithNamespace: {
      type: String,
      required: true,
    },
    disabled: {
      type: Boolean,
      required: false,
      default: false,
    },
    formPath: {
      type: String,
      required: true,
    },
    isFork: {
      type: Boolean,
      required: true,
    },
    issuesCount: {
      type: Number,
      required: true,
    },
    mergeRequestsCount: {
      type: Number,
      required: true,
    },
    forksCount: {
      type: Number,
      required: true,
    },
    starsCount: {
      type: Number,
      required: true,
    },
    buttonText: {
      type: String,
      required: false,
      default: __('Delete project'),
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

    <delete-modal
      v-model="isModalVisible"
      :confirm-phrase="confirmPhrase"
      :name-with-namespace="nameWithNamespace"
      :is-fork="isFork"
      :issues-count="issuesCount"
      :merge-requests-count="mergeRequestsCount"
      :forks-count="forksCount"
      :stars-count="starsCount"
      @primary="submitForm"
    >
      <template #modal-footer>
        <slot name="modal-footer"></slot>
      </template>
    </delete-modal>

    <gl-button
      category="primary"
      variant="danger"
      data-testid="delete-button"
      :disabled="disabled"
      @click="onButtonClick"
      >{{ buttonText }}</gl-button
    >
  </gl-form>
</template>

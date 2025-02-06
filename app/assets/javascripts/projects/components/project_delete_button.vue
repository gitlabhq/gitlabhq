<script>
import SharedDeleteButton from './shared/delete_button.vue';

export default {
  components: {
    SharedDeleteButton,
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
      required: true,
    },
  },
};
</script>

<template>
  <shared-delete-button
    :confirm-phrase="confirmPhrase"
    :name-with-namespace="nameWithNamespace"
    :disabled="disabled"
    :form-path="formPath"
    :is-fork="isFork"
    :issues-count="issuesCount"
    :merge-requests-count="mergeRequestsCount"
    :forks-count="forksCount"
    :stars-count="starsCount"
    :button-text="buttonText"
  />
</template>

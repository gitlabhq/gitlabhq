<script>
import { __ } from '~/locale';
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
    buttonText: {
      type: String,
      required: false,
      default: __('Delete project'),
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
  },
};
</script>

<template>
  <shared-delete-button
    :confirm-phrase="confirmPhrase"
    :button-text="buttonText"
    :form-path="formPath"
    :is-fork="isFork"
    :issues-count="issuesCount"
    :merge-requests-count="mergeRequestsCount"
    :forks-count="forksCount"
    :stars-count="starsCount"
  />
</template>

<script>
  import { mapActions } from 'vuex';

  export default {
    name: 'TestIssueBody',
    props: {
      issue: {
        type: Object,
        required: true,
      },
      // failed || success
      status: {
        type: String,
        required: true,
      },
      isNew: {
        type: Boolean,
        required: false,
        default: false,
      },
    },
    methods: {
      ...mapActions(['openModal']),
    },
  };
</script>
<template>
  <div class="report-block-list-issue-description prepend-top-5 append-bottom-5">
    <div class="report-block-list-issue-description-text">
      <button
        type="button"
        class="btn-link btn-blank text-left break-link vulnerability-name-button"
        @click="openModal({ issue })"
      >
        <div
          v-if="isNew"
          class="badge badge-danger append-right-5"
        >
          {{ s__('New') }}
        </div>{{ issue.name }}
      </button>
    </div>
  </div>
</template>

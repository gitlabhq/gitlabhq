<script>
  import axios from '~/lib/utils/axios_utils';
  import modal from '~/vue_shared/components/modal.vue';
  import { redirectTo } from '~/lib/utils/url_utility';

  export default {
    components: {
      modal,
    },
    props: {
      labelTitle: {
        type: String,
        required: true,
      },
      labelOpenMergeRequestsCount: {
        type: Number,
        required: true,
      },
      labelOpenIssuesCount: {
        type: Number,
        required: true,
      },
      url: {
        type: String,
        required: true,
      },
    },
    computed: {
      modalTitle() {
        return `Delete label ‘${this.labelTitle}’?`;
      },
      modalDescription() {
        return `You’re about to permanently delete the label ${this.labelTitle} from this project and remove it from 
        ${this.labelOpenIssuesCount}, ${this.labelOpenMergeRequestsCount} issues and merge requests. 
        Once deleted, it cannot be undone or recovered.`;
      },
      primaryButtonText() {
        return 'Delete Label';
      },
    },
    methods: {
      onSubmit() {
        axios.delete(this.url)
        .then((resp) => {
          redirectTo(resp.request.responseURL);
        })
        .catch((err) => {
          Flash(err);
        });
      },
    },
  };
</script>
<template>
  <modal
    id="delete-label-modal"
    :title="modalTitle"
    :text="modalDescription"
    kind="danger"
    :primary-button-label="primaryButtonText"
    @submit="onSubmit"
  />
</template>

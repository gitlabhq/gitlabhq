<script>
  import axios from '~/lib/utils/axios_utils';
  import modal from '~/vue_shared/components/modal.vue';
  import { redirectTo } from '~/lib/utils/url_utility';
  import { s__, sprintf } from '~/locale';
  import Flash from '~/flash';
  import eventHub from '../event_hub';

  export default {
    components: {
      modal,
    },
    props: {
      labelTitle: {
        type: String,
        required: true,
      },
      openMergeRequestCount: {
        type: Number,
        required: true,
      },
      openIssuesCount: {
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
        return sprintf(s__('Labels|Delete label ‘%{labelTitle}’?'), { labelTitle: this.labelTitle });
      },
      modalDescription() {
        return sprintf(s__(`Labels|You’re about to permanently delete the label <strong>%{labelTitle}</strong> 
        from this project and remove it from %{openIssuesCount} issues and %{openMergeRequestCount} merge requests. 
        Once deleted, it cannot be undone or recovered.`), {
          labelTitle: this.labelTitle,
          openIssuesCount: this.openIssuesCount,
          openMergeRequestCount: this.openMergeRequestCount,
        });
      },
      primaryButtonText() {
        return s__('Labels|Delete Label');
      },
    },
    methods: {
      onSubmit() {
        eventHub.$emit('deleteLabelModal.requestStarted', this.url);
        return axios.delete(this.url)
          .then((response) => {
            eventHub.$emit('deleteLabelModal.requestFinished', { labelUrl: this.url, successful: true });

            redirectTo(response.request.responseURL);
          })
          .catch((error) => {
            eventHub.$emit('deleteLabelModal.requestFinished', { labelUrl: this.url, successful: false });

            Flash(error);

            throw error;
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
    @submit="onSubmit">

    <template
      slot="body"
      slot-scope="props">
      <p v-html="props.text"></p>
    </template>
  </modal>
</template>

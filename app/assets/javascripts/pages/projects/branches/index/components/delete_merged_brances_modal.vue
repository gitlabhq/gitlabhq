<script>
  import axios from '~/lib/utils/axios_utils';
  import { s__, sprintf } from '~/locale';
  import Flash from '~/flash';
  import modal from '~/vue_shared/components/modal.vue';
  import { redirectTo } from '~/lib/utils/url_utility';

  export default {
    components: {
      modal,
    },
    props: {
      defaultBranch: {
        type: String,
        required: true,
      },
      url: {
        type: String,
        required: true,
      },
    },
    computed: {
      modalText() {
        return sprintf(s__(`You’re about to permanently delete all merged branches 
        that were merged into ‘%{defaultBranchName}’. 
        Once you confirm and press Delete merged branches, it cannot be undone or recovered.`),
        { defaultBranchName: this.defaultBranch });
      },
    },
    methods: {
      onSubmit() {
        axios.delete(this.url)
        .then((resp) => {
          redirectTo(resp.request.responseURL);
        })
        .catch(() => {
          // TODO: Check with UX for the error message
          Flash(s__('Branches|Deleting the merged branches failed'));
        });
      },
    },
  };
</script>
<template>
  <modal
    id="delete-merged-branches-modal"
    :title="s__('Branches|Delete all merged branches?')"
    :text="modalText"
    kind="danger"
    :primary-button-label="s__('Branches|Delete merged branches')"
    @submit="onSubmit"
  />
</template>

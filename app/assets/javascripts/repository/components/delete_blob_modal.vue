<script>
import axios from '~/lib/utils/axios_utils';
import { visitUrl } from '~/lib/utils/url_utility';
import { logError } from '~/lib/logger';
import { createAlert } from '~/alert';
import { __ } from '~/locale';
import { glListenersMixin } from '~/lib/utils/vue3compat/gl_listeners_mixin';
import CommitChangesModal from './commit_changes_modal.vue';

export default {
  name: 'DeleteBlobModal',
  components: {
    CommitChangesModal,
  },
  mixins: [glListenersMixin],
  props: {
    deletePath: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      loading: false,
    };
  },
  methods: {
    // eslint-disable-next-line vue/no-unused-properties -- called via $refs by parent components
    show() {
      this.$refs.modal.show();
    },
    handleBlobDelete(formData) {
      this.loading = true;

      return axios({
        method: 'post',
        url: this.deletePath,
        data: formData,
      })
        .then((response) => {
          visitUrl(response.data.filePath);
        })
        .catch((e) => {
          // eslint-disable-next-line @gitlab/require-i18n-strings
          logError('Failed to delete file. See exception details for more information.', e);
          createAlert({ message: __('Failed to delete file! Please try again.'), error: e });
        })
        .finally(() => {
          this.loading = false;
        });
    },
  },
};
</script>
<template>
  <commit-changes-modal
    ref="modal"
    :loading="loading"
    v-bind="$attrs"
    v-on="glListeners()"
    @submit-form="handleBlobDelete"
  >
    <template #form-fields>
      <input type="hidden" name="_method" value="delete" />
    </template>
  </commit-changes-modal>
</template>

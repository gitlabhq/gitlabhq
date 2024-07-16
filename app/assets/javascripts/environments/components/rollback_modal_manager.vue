<script>
import { parseBoolean } from '~/lib/utils/common_utils';
import ConfirmRollbackModal from './confirm_rollback_modal.vue';

export default {
  components: {
    ConfirmRollbackModal,
  },
  props: {
    selector: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      environment: null,
      visible: false,
    };
  },
  mounted() {
    document.querySelectorAll(this.selector).forEach((button) => {
      button.addEventListener('click', (e) => {
        e.preventDefault();
        const { environmentName, commitShortSha, commitUrl, isLastDeployment, retryPath } =
          button.dataset;

        this.environment = {
          name: environmentName,
          commitShortSha,
          commitUrl,
          retryUrl: retryPath,
          isLastDeployment: parseBoolean(isLastDeployment),
        };
        this.visible = true;
      });
    });
  },
};
</script>

<template>
  <confirm-rollback-modal
    v-if="environment"
    v-model="visible"
    :environment="environment"
    :has-multiple-commits="false"
  />
</template>

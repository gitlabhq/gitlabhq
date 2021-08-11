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
      retryPath: '',
      visible: false,
    };
  },
  mounted() {
    document.querySelectorAll(this.selector).forEach((button) => {
      button.addEventListener('click', (e) => {
        e.preventDefault();
        const {
          environmentName,
          commitShortSha,
          commitUrl,
          isLastDeployment,
          retryPath,
        } = button.dataset;

        this.environment = {
          name: environmentName,
          commitShortSha,
          commitUrl,
          isLastDeployment: parseBoolean(isLastDeployment),
        };
        this.retryPath = retryPath;
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
    :retry-url="retryPath"
  />
  <div v-else></div>
</template>

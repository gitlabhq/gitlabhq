<script>
import { parseBoolean } from '~/lib/utils/common_utils';
import { redirectTo } from '~/lib/utils/url_utility';
import eventHub from '../event_hub';
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
    eventHub.$on('rollbackEnvironment', () => {
      redirectTo(this.retryPath);
    });

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
  />
  <div v-else></div>
</template>

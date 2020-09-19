<script>
import { GlAlert, GlButton } from '@gitlab/ui';
import axios from '~/lib/utils/axios_utils';

export default {
  components: {
    GlAlert,
    GlButton,
  },
  props: {
    dismissEndpoint: {
      type: String,
      required: true,
    },
    featureId: {
      type: String,
      required: true,
    },
    editPath: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      showAlert: true,
    };
  },
  methods: {
    dismissAlert() {
      this.showAlert = false;

      return axios.post(this.dismissEndpoint, {
        feature_name: this.featureId,
      });
    },
  },
};
</script>

<template>
  <gl-alert v-if="showAlert" class="gl-mt-5" @dismiss="dismissAlert">
    {{ __('The Web IDE offers advanced syntax highlighting capabilities and more.') }}
    <div class="gl-mt-5">
      <gl-button :href="editPath" category="primary" variant="info">{{
        __('Open Web IDE')
      }}</gl-button>
    </div>
  </gl-alert>
</template>

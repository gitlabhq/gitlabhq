<script>
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import FormUrlApp from './form_url_app.vue';
import FormCustomHeaders from './form_custom_headers.vue';

export default {
  components: {
    FormUrlApp,
    FormCustomHeaders,
  },
  mixins: [glFeatureFlagsMixin()],
  props: {
    initialUrl: {
      type: String,
      required: false,
      default: null,
    },
    initialUrlVariables: {
      type: Array,
      required: false,
      default: null,
    },
    initialCustomHeaders: {
      type: Array,
      required: false,
      default: null,
    },
  },
};
</script>

<template>
  <div>
    <form-url-app :initial-url="initialUrl" :initial-url-variables="initialUrlVariables" />
    <form-custom-headers
      v-if="glFeatures.customWebhookHeaders"
      :initial-custom-headers="initialCustomHeaders"
    />
  </div>
</template>

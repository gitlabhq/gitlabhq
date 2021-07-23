<script>
import createFlash from '~/flash';
import axios from '~/lib/utils/axios_utils';
import { visitUrl } from '~/lib/utils/url_utility';
import EnvironmentForm from './environment_form.vue';

export default {
  components: {
    EnvironmentForm,
  },
  inject: ['projectEnvironmentsPath', 'updateEnvironmentPath'],
  props: {
    environment: {
      required: true,
      type: Object,
    },
  },
  data() {
    return {
      formEnvironment: {
        name: this.environment.name,
        externalUrl: this.environment.external_url,
      },
    };
  },
  methods: {
    onChange(environment) {
      this.formEnvironment = environment;
    },
    onSubmit() {
      axios
        .put(this.updateEnvironmentPath, {
          id: this.environment.id,
          name: this.formEnvironment.name,
          external_url: this.formEnvironment.externalUrl,
        })
        .then(({ data: { path } }) => visitUrl(path))
        .catch((error) => {
          const message = error.response.data.message[0];
          createFlash({ message });
        });
    },
  },
};
</script>
<template>
  <environment-form
    :cancel-path="projectEnvironmentsPath"
    :environment="formEnvironment"
    :title="__('Edit environment')"
    @change="onChange"
    @submit="onSubmit"
  />
</template>

<script>
import createFlash from '~/flash';
import axios from '~/lib/utils/axios_utils';
import { visitUrl } from '~/lib/utils/url_utility';
import EnvironmentForm from './environment_form.vue';

export default {
  components: {
    EnvironmentForm,
  },
  inject: ['projectEnvironmentsPath'],
  data() {
    return {
      environment: {
        name: '',
        externalUrl: '',
      },
    };
  },
  methods: {
    onChange(env) {
      this.environment = env;
    },
    onSubmit() {
      axios
        .post(this.projectEnvironmentsPath, {
          name: this.environment.name,
          external_url: this.environment.externalUrl,
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
    :environment="environment"
    :title="__('New environment')"
    @change="onChange($event)"
    @submit="onSubmit"
  />
</template>

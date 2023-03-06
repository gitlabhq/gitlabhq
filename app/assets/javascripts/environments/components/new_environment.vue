<script>
import { createAlert } from '~/alert';
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
      loading: false,
    };
  },
  methods: {
    onChange(env) {
      this.environment = env;
    },
    onSubmit() {
      this.loading = true;
      axios
        .post(this.projectEnvironmentsPath, {
          name: this.environment.name,
          external_url: this.environment.externalUrl,
        })
        .then(({ data: { path } }) => visitUrl(path))
        .catch((error) => {
          const message = error.response.data.message[0];
          createAlert({ message });
          this.loading = false;
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
    :loading="loading"
    @change="onChange($event)"
    @submit="onSubmit"
  />
</template>

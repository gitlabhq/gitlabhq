<script>
import { createAlert } from '~/alert';
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
        id: this.environment.id,
        name: this.environment.name,
        externalUrl: this.environment.external_url,
      },
      loading: false,
    };
  },
  methods: {
    onChange(environment) {
      this.formEnvironment = environment;
    },
    onSubmit() {
      this.loading = true;
      axios
        .put(this.updateEnvironmentPath, {
          id: this.environment.id,
          external_url: this.formEnvironment.externalUrl,
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
    :environment="formEnvironment"
    :title="__('Edit environment')"
    :loading="loading"
    @change="onChange"
    @submit="onSubmit"
  />
</template>

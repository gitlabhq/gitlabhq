<script>
import { createAlert } from '~/alert';
import { visitUrl } from '~/lib/utils/url_utility';
import createEnvironment from '../graphql/mutations/create_environment.mutation.graphql';
import EnvironmentForm from './environment_form.vue';

export default {
  components: {
    EnvironmentForm,
  },
  inject: ['projectEnvironmentsPath', 'projectPath'],
  data() {
    return {
      environment: {
        name: '',
        description: '',
        externalUrl: '',
        clusterAgentId: null,
      },
      loading: false,
    };
  },
  methods: {
    onChange(env) {
      this.environment = env;
    },
    async onSubmit() {
      this.loading = true;
      try {
        const { data } = await this.$apollo.mutate({
          mutation: createEnvironment,
          variables: {
            input: {
              name: this.environment.name,
              description: this.environment.description,
              externalUrl: this.environment.externalUrl,
              projectPath: this.projectPath,
              clusterAgentId: this.environment.clusterAgentId,
              kubernetesNamespace: this.environment.kubernetesNamespace,
              fluxResourcePath: this.environment.fluxResourcePath,
            },
          },
        });

        const { errors } = data.environmentCreate;

        if (errors.length > 0) {
          throw new Error(errors[0]?.message ?? errors[0]);
        }

        const { path } = data.environmentCreate.environment;

        if (path) {
          visitUrl(path);
        }
      } catch (error) {
        const { message } = error;
        createAlert({ message });
      } finally {
        this.loading = false;
      }
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

<script>
import { createAlert } from '~/alert';
import axios from '~/lib/utils/axios_utils';
import { visitUrl } from '~/lib/utils/url_utility';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import createEnvironment from '../graphql/mutations/create_environment.mutation.graphql';
import EnvironmentForm from './environment_form.vue';

export default {
  components: {
    EnvironmentForm,
  },
  mixins: [glFeatureFlagsMixin()],
  inject: ['projectEnvironmentsPath', 'projectPath'],
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
      if (this.glFeatures?.environmentSettingsToGraphql) {
        this.createWithGraphql();
      } else {
        this.createWithAxios();
      }
    },
    async createWithGraphql() {
      this.loading = true;
      try {
        const { data } = await this.$apollo.mutate({
          mutation: createEnvironment,
          variables: {
            input: {
              name: this.environment.name,
              externalUrl: this.environment.externalUrl,
              projectPath: this.projectPath,
              clusterAgentId: this.environment.clusterAgentId,
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
    createWithAxios() {
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

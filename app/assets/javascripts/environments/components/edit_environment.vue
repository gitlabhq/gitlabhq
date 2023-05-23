<script>
import { GlLoadingIcon } from '@gitlab/ui';
import { createAlert } from '~/alert';
import axios from '~/lib/utils/axios_utils';
import { visitUrl } from '~/lib/utils/url_utility';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import getEnvironment from '../graphql/queries/environment.query.graphql';
import updateEnvironment from '../graphql/mutations/update_environment.mutation.graphql';
import EnvironmentForm from './environment_form.vue';

export default {
  components: {
    GlLoadingIcon,
    EnvironmentForm,
  },
  mixins: [glFeatureFlagsMixin()],
  inject: ['projectEnvironmentsPath', 'updateEnvironmentPath', 'projectPath', 'environmentName'],
  apollo: {
    environment: {
      query: getEnvironment,
      variables() {
        return {
          environmentName: this.environmentName,
          projectFullPath: this.projectPath,
        };
      },
      update(data) {
        this.formEnvironment = data?.project?.environment || {};
      },
    },
  },
  data() {
    return {
      loading: false,
      formEnvironment: null,
    };
  },
  computed: {
    isQueryLoading() {
      return this.$apollo.queries.environment.loading;
    },
  },
  methods: {
    onChange(environment) {
      this.formEnvironment = environment;
    },
    onSubmit() {
      if (this.glFeatures?.environmentSettingsToGraphql) {
        this.updateWithGraphql();
      } else {
        this.updateWithAxios();
      }
    },
    async updateWithGraphql() {
      this.loading = true;
      try {
        const { data } = await this.$apollo.mutate({
          mutation: updateEnvironment,
          variables: {
            input: {
              id: this.formEnvironment.id,
              externalUrl: this.formEnvironment.externalUrl,
            },
          },
        });

        const { errors } = data.environmentUpdate;

        if (errors.length > 0) {
          throw new Error(errors[0]?.message ?? errors[0]);
        }

        const { path } = data.environmentUpdate.environment;

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
    updateWithAxios() {
      this.loading = true;
      axios
        .put(this.updateEnvironmentPath, {
          id: this.formEnvironment.id,
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
  <gl-loading-icon v-if="isQueryLoading" class="gl-mt-5" />
  <environment-form
    v-else-if="formEnvironment"
    :cancel-path="projectEnvironmentsPath"
    :environment="formEnvironment"
    :title="__('Edit environment')"
    :loading="loading"
    @change="onChange"
    @submit="onSubmit"
  />
</template>

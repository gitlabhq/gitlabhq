<script>
import { GlLoadingIcon } from '@gitlab/ui';
import { createAlert } from '~/alert';
import axios from '~/lib/utils/axios_utils';
import { visitUrl } from '~/lib/utils/url_utility';
import getEnvironment from '../graphql/queries/environment.query.graphql';
import EnvironmentForm from './environment_form.vue';

export default {
  components: {
    GlLoadingIcon,
    EnvironmentForm,
  },
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

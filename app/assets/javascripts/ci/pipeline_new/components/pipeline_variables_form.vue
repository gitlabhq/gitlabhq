<script>
import { GlLoadingIcon, GlFormGroup } from '@gitlab/ui';
import { fetchPolicies } from '~/lib/graphql';
import { reportToSentry } from '~/ci/utils';
import ciConfigVariablesQuery from '../graphql/queries/ci_config_variables.graphql';

export default {
  name: 'PipelineVariablesForm',
  components: {
    GlLoadingIcon,
    GlFormGroup,
  },
  props: {
    projectPath: {
      type: String,
      required: true,
    },
    refParam: {
      type: String,
      required: true,
    },
    defaultBranch: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      ciConfigVariables: null,
      refValue: {
        shortName: this.refParam,
        fullName: this.refParam === this.defaultBranch ? `refs/heads/${this.refParam}` : undefined,
      },
    };
  },
  apollo: {
    ciConfigVariables: {
      fetchPolicy: fetchPolicies.NO_CACHE,
      query: ciConfigVariablesQuery,
      variables() {
        return {
          fullPath: this.projectPath,
          ref: this.refQueryParam,
        };
      },
      update({ project }) {
        return project?.ciConfigVariables || [];
      },

      error(error) {
        reportToSentry(this.$options.name, error);
      },
    },
  },
  computed: {
    isFetchingCiConfigVariables() {
      return this.ciConfigVariables === null;
    },
    isLoading() {
      return this.$apollo.queries.ciConfigVariables.loading || this.isFetchingCiConfigVariables;
    },
    refQueryParam() {
      return this.refValue.fullName || this.refValue.shortName;
    },
  },
};
</script>

<template>
  <div>
    <gl-loading-icon v-if="isLoading" class="gl-mb-5" size="md" />
    <gl-form-group v-else>
      <pre>{{ ciConfigVariables }}</pre>
    </gl-form-group>
  </div>
</template>

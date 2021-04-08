<script>
import { GlButton } from '@gitlab/ui';
import { redirectTo } from '~/lib/utils/url_utility';
import { s__ } from '~/locale';
import configureSastMutation from '~/security_configuration/graphql/configure_sast.mutation.graphql';

export default {
  components: {
    GlButton,
  },
  inject: {
    projectPath: {
      from: 'projectPath',
      default: '',
    },
  },
  data() {
    return {
      isLoading: false,
    };
  },
  methods: {
    async mutate() {
      this.isLoading = true;
      try {
        const { data } = await this.$apollo.mutate({
          mutation: configureSastMutation,
          variables: {
            input: {
              projectPath: this.projectPath,
              configuration: { global: [], pipeline: [], analyzers: [] },
            },
          },
        });
        const { errors, successPath } = data.configureSast;

        if (errors.length > 0) {
          throw new Error(errors[0]);
        }

        if (!successPath) {
          throw new Error(s__('SecurityConfiguration|SAST merge request creation mutation failed'));
        }

        redirectTo(successPath);
      } catch (e) {
        this.$emit('error', e.message);
        this.isLoading = false;
      }
    },
  },
};
</script>

<template>
  <gl-button :loading="isLoading" variant="success" category="secondary" @click="mutate">{{
    s__('SecurityConfiguration|Configure via merge request')
  }}</gl-button>
</template>

<script>
import { GlToggle } from '@gitlab/ui';

import groupRunnersEnabledQuery from '../graphql/group_runners_enabled.query.graphql';
import groupRunnersEnabledMutation from '../graphql/group_runners_enabled.mutation.graphql';

export default {
  name: 'GroupRunnersToggle',
  components: {
    GlToggle,
  },
  props: {
    projectFullPath: {
      type: String,
      required: true,
    },
  },
  emits: ['change', 'error'],
  data() {
    return {
      isLoading: true,
      groupRunnersEnabled: null,
    };
  },
  apollo: {
    groupRunnersEnabled: {
      query: groupRunnersEnabledQuery,
      variables() {
        return { fullPath: this.projectFullPath };
      },
      update(data) {
        return data.project?.ciCdSettings?.groupRunnersEnabled;
      },
      result() {
        this.isLoading = false;
        this.$emit('change', this.groupRunnersEnabled);
      },
      error(error) {
        this.$emit('error', error);
      },
    },
  },
  methods: {
    async toggleGroupRunners(value) {
      if (this.isLoading) {
        return;
      }
      this.isLoading = true;
      try {
        const { data } = await this.$apollo.mutate({
          mutation: groupRunnersEnabledMutation,
          variables: {
            input: {
              fullPath: this.projectFullPath,
              groupRunnersEnabled: value,
            },
          },
        });

        const { errors, ciCdSettings } = data.projectCiCdSettingsUpdate;
        if (errors.length) {
          throw new Error(errors.join(' '));
        }

        this.groupRunnersEnabled = ciCdSettings.groupRunnersEnabled;
        this.$emit('change', this.groupRunnersEnabled);
      } catch (error) {
        this.$emit('error', error);
      } finally {
        this.isLoading = false;
      }
    },
  },
};
</script>

<template>
  <gl-toggle
    label-position="left"
    :is-loading="isLoading"
    :value="groupRunnersEnabled"
    @change="toggleGroupRunners"
  >
    <template #label>
      <span class="gl-text-sm gl-font-normal gl-text-subtle">{{
        s__('Runners|Turn on group runners for this project')
      }}</span>
    </template>
  </gl-toggle>
</template>

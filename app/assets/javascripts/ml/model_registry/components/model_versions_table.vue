<script>
import { GlAvatarLink, GlAvatar, GlTable, GlLink, GlTooltip } from '@gitlab/ui';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';
import { s__ } from '~/locale';
import { createAlert, VARIANT_DANGER } from '~/alert';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import deleteModelVersionMutation from '~/ml/model_registry/graphql/mutations/delete_model_version.mutation.graphql';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import { TYPENAME_MODEL_VERSION } from '~/ml/model_registry/constants';
import ModelVersionActionsDropdown from './model_version_actions_dropdown.vue';

export default {
  name: 'ModelVersionsTable',
  components: {
    GlAvatarLink,
    GlTable,
    TimeAgoTooltip,
    GlAvatar,
    GlLink,
    ModelVersionActionsDropdown,
  },
  directives: {
    GlTooltip,
  },
  inject: ['canWriteModelRegistry'],
  props: {
    items: {
      type: Array,
      required: true,
    },
  },
  computed: {
    computedFields() {
      return [
        { key: 'version', label: s__('ModelRegistry|Version'), thClass: 'gl-w-1/3' },
        { key: 'createdAt', label: s__('ModelRegistry|Created'), thClass: 'gl-w-1/3' },
        { key: 'author', label: s__('ModelRegistry|Created by') },
        {
          key: 'actions',
          label: '',
          tdClass: 'lg:gl-w-px gl-whitespace-nowrap !gl-p-3 gl-text-right',
          thClass: 'lg:gl-w-px gl-whitespace-nowrap',
        },
      ];
    },
  },
  methods: {
    handleDeleteError(error) {
      Sentry.captureException(error, {
        tags: {
          vue_component: 'model_versions_table',
        },
      });
      createAlert({
        message: s__(
          'MlModelRegistry|Something went wrong while trying to delete the model version. Please try again later.',
        ),
        variant: VARIANT_DANGER,
      });
    },
    async deleteModelVersion(modelVersionId) {
      try {
        const { data } = await this.$apollo.mutate({
          mutation: deleteModelVersionMutation,
          variables: {
            id: convertToGraphQLId(TYPENAME_MODEL_VERSION, modelVersionId),
          },
        });

        if (data.mlModelVersionDelete?.errors?.length > 0) {
          throw data.mlModelVersionDelete.errors.join(', ');
        }

        this.$emit('model-versions-update');
      } catch (error) {
        this.handleDeleteError(error);
      }
    },
  },
};
</script>

<template>
  <gl-table class="fixed" :sticky-header="false" :items="items" :fields="computedFields">
    <template #cell(version)="{ item }">
      <gl-link :href="item._links.showPath">
        <b>{{ item.version }}</b>
      </gl-link>
    </template>
    <template #cell(createdAt)="{ item: { createdAt } }">
      <time-ago-tooltip :time="createdAt" />
    </template>
    <template #cell(author)="{ item: { author } }">
      <gl-avatar-link
        v-if="author"
        :href="author.webUrl"
        :title="author.name"
        class="js-user-link !gl-text-subtle"
      >
        <gl-avatar :src="author.avatarUrl" :size="16" :entity-name="author.name" class="mr-2" />
        {{ author.name }}
      </gl-avatar-link>
    </template>
    <template #cell(actions)="{ item }">
      <model-version-actions-dropdown
        v-if="canWriteModelRegistry"
        :model-version="item"
        @delete-model-version="deleteModelVersion"
      />
    </template>
  </gl-table>
</template>

<script>
import { GlButton, GlIcon, GlLink, GlTable, GlLoadingIcon } from '@gitlab/ui';
import { TYPENAME_GROUP } from '~/graphql_shared/constants';
import ProjectAvatar from '~/vue_shared/components/project_avatar.vue';
import { s__, __ } from '~/locale';

export default {
  fields: [
    {
      key: 'fullPath',
      label: s__('CICD|Group or project'),
      tdClass: 'gl-w-full',
    },
    {
      key: 'actions',
      label: __('Actions'),
      class: 'gl-text-right !gl-pl-0',
      tdClass: '!gl-py-0 !gl-align-middle',
    },
  ],
  components: {
    GlButton,
    GlIcon,
    GlLink,
    GlTable,
    GlLoadingIcon,
    ProjectAvatar,
  },
  inject: {
    fullPath: {
      default: '',
    },
  },
  props: {
    isGroup: {
      type: Boolean,
      required: false,
      default: false,
    },
    items: {
      type: Array,
      required: true,
    },
    loading: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  methods: {
    itemType(item) {
      // eslint-disable-next-line no-underscore-dangle
      return item.__typename === TYPENAME_GROUP ? 'group' : 'project';
    },
  },
};
</script>

<template>
  <gl-table :items="items" :fields="$options.fields" :busy="loading" class="gl-mb-0">
    <template #table-busy>
      <gl-loading-icon size="md" />
    </template>
    <template #cell(fullPath)="{ item }">
      <div class="gl-inline-flex gl-items-center">
        <gl-icon
          :name="itemType(item)"
          class="gl-mr-3 gl-shrink-0"
          :data-testid="`token-access-${itemType(item)}-icon`"
        />
        <project-avatar
          :alt="item.name"
          :project-avatar-url="item.avatarUrl"
          :project-id="item.id"
          :project-name="item.name"
          class="gl-mr-3"
          :size="24"
          :data-testid="`token-access-${itemType(item)}-avatar`"
        />
        <gl-link :href="item.webUrl" :data-testid="`token-access-${itemType(item)}-name`">
          {{ item.fullPath }}
        </gl-link>
      </div>
    </template>

    <template #cell(actions)="{ item }">
      <gl-button
        v-if="item.fullPath !== fullPath"
        category="primary"
        icon="remove"
        :aria-label="__('Remove access')"
        @click="$emit('removeItem', item)"
      />
    </template>
  </gl-table>
</template>

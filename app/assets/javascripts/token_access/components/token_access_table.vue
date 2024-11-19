<script>
import { GlButton, GlIcon, GlLink, GlTableLite } from '@gitlab/ui';
import { TYPENAME_GROUP } from '~/graphql_shared/constants';
import ProjectAvatar from '~/vue_shared/components/project_avatar.vue';
import { s__, __ } from '~/locale';

export default {
  fields: [
    {
      key: 'fullPath',
      label: s__('CICD|Group or project'),
      tdClass: 'gl-w-3/4',
    },
    {
      key: 'actions',
      label: __('Actions'),
      class: 'gl-text-right',
      tdClass: '!gl-py-0 !gl-pl-0 gl-w-0 !gl-align-middle',
    },
  ],
  components: {
    GlButton,
    GlIcon,
    GlLink,
    GlTableLite,
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
  <gl-table-lite :items="items" :fields="$options.fields" class="gl-mb-0">
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
  </gl-table-lite>
</template>

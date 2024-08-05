<script>
import { GlButton, GlIcon, GlLink, GlTableLite } from '@gitlab/ui';
import { TYPENAME_GROUP } from '~/graphql_shared/constants';
import ProjectAvatar from '~/vue_shared/components/project_avatar.vue';

export default {
  fields: [
    {
      key: 'fullPath',
      label: '',
      tdClass: 'gl-w-3/4',
    },
    {
      key: 'actions',
      label: '',
      tdClass: 'gl-w-1/4 gl-text-right',
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
  <gl-table-lite
    :items="items"
    :fields="$options.fields"
    :tbody-tr-attr="{ 'data-testid': 'token-access-table-row' }"
    thead-class="gl-hidden"
    class="gl-mb-0"
    fixed
  >
    <template #cell(fullPath)="{ item }">
      <div class="gl-inline-flex gl-items-center">
        <gl-icon
          :name="itemType(item)"
          class="gl-mr-3 gl-flex-shrink-0"
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
        <gl-link
          class="gl-text-gray-900"
          :href="`/${item.fullPath}`"
          :data-testid="`token-access-${itemType(item)}-name`"
          >{{ item.fullPath }}</gl-link
        >
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

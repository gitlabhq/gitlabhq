<!-- eslint-disable vue/multi-word-component-names -->
<script>
import { GlLoadingIcon, GlTableLite, GlTabs, GlTab, GlBadge, GlKeysetPagination } from '@gitlab/ui';
import { __ } from '~/locale';
import { localeDateFormat } from '~/lib/utils/datetime/locale_dateformat';
import DeleteItem from './delete_item.vue';

export default {
  components: {
    GlTableLite,
    GlLoadingIcon,
    GlTabs,
    GlTab,
    GlBadge,
    GlKeysetPagination,
    DeleteItem,
  },
  props: {
    loading: {
      type: Boolean,
      required: false,
      default: false,
    },
    customEmojis: {
      type: Array,
      required: true,
    },
    pageInfo: {
      type: Object,
      required: true,
    },
    count: {
      type: Number,
      required: true,
    },
    userPermissions: {
      type: Object,
      required: true,
    },
  },
  computed: {
    primaryAction() {
      if (!this.userPermissions.createCustomEmoji) return undefined;

      return {
        text: __('New custom emoji'),
        attributes: {
          variant: 'confirm',
          to: '/new',
        },
      };
    },
  },
  methods: {
    prevPage() {
      this.$emit('input', {
        before: this.pageInfo.startCursor,
      });
    },
    nextPage() {
      this.$emit('input', {
        after: this.pageInfo.endCursor,
      });
    },
    formatDate(date) {
      return localeDateFormat.asDate.format(date);
    },
  },
  fields: [
    {
      key: 'emoji',
      label: __('Image'),
      thClass: '!gl-border-t-0',
      tdClass: '!gl-align-middle',
      columnWidth: '70px',
    },
    {
      key: 'name',
      label: __('Name'),
      thClass: '!gl-border-t-0',
      tdClass: '!gl-align-middle gl-font-monospace',
    },
    {
      key: 'created_at',
      label: __('Created date'),
      thClass: '!gl-border-t-0',
      tdClass: '!gl-align-middle',
      columnWidth: '25%',
    },
    {
      key: 'action',
      label: '',
      thClass: '!gl-border-t-0',
      columnWidth: '64px',
    },
  ],
};
</script>

<template>
  <div>
    <gl-loading-icon v-if="loading" size="lg" />
    <template v-else>
      <gl-tabs content-class="gl-pt-0" :action-primary="primaryAction">
        <gl-tab>
          <template #title>
            {{ __('Emoji') }}
            <gl-badge class="gl-tab-counter-badge">{{ count }}</gl-badge>
          </template>
          <gl-table-lite
            :items="customEmojis"
            :fields="$options.fields"
            table-class="gl-table-fixed"
          >
            <template #table-colgroup="scope">
              <col
                v-for="field in scope.fields"
                :key="field.key"
                :style="{ width: field.columnWidth }"
              />
            </template>
            <template #cell(emoji)="data">
              <gl-emoji
                :data-name="data.item.name"
                :data-fallback-src="data.item.url"
                data-unicode-version="custom"
              />
            </template>
            <template #cell(action)="data">
              <delete-item
                v-if="data.item.userPermissions.deleteCustomEmoji"
                :key="data.item.name"
                :emoji="data.item"
              />
            </template>
            <template #cell(created_at)="data">
              {{ formatDate(data.item.createdAt) }}
            </template>
            <template #cell(name)="data">
              <strong class="gl-str-truncated">:{{ data.item.name }}:</strong>
            </template>
          </gl-table-lite>
          <gl-keyset-pagination
            v-if="pageInfo.hasPreviousPage || pageInfo.hasNextPage"
            v-bind="pageInfo"
            class="gl-mt-4"
            @prev="prevPage"
            @next="nextPage"
          />
        </gl-tab>
      </gl-tabs>
    </template>
  </div>
</template>

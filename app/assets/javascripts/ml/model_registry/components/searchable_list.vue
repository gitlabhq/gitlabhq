<script>
import { GlAlert } from '@gitlab/ui';
import PackagesListLoader from '~/packages_and_registries/shared/components/packages_list_loader.vue';
import RegistryList from '~/packages_and_registries/shared/components/registry_list.vue';
import { GRAPHQL_PAGE_SIZE } from '~/ml/model_registry/constants';

export default {
  name: 'SearchableList',
  components: { PackagesListLoader, RegistryList, GlAlert },
  props: {
    items: {
      type: Array,
      required: true,
    },
    pageInfo: {
      type: Object,
      required: true,
    },
    isLoading: {
      type: Boolean,
      required: false,
      default: false,
    },
    errorMessage: {
      type: String,
      required: false,
      default: '',
    },
  },
  computed: {
    isListEmpty() {
      return this.items.length === 0;
    },
  },
  methods: {
    prevPage() {
      const pageInfo = {
        first: null,
        last: GRAPHQL_PAGE_SIZE,
        before: this.pageInfo.startCursor,
      };

      this.$emit('fetch-page', pageInfo);
    },
    nextPage() {
      const pageInfo = {
        first: GRAPHQL_PAGE_SIZE,
        last: null,
        after: this.pageInfo.endCursor,
      };

      this.$emit('fetch-page', pageInfo);
    },
  },
};
</script>

<template>
  <div>
    <packages-list-loader v-if="isLoading" />
    <gl-alert v-else-if="errorMessage" variant="danger" :dismissible="false">
      {{ errorMessage }}
    </gl-alert>
    <slot v-else-if="isListEmpty" name="empty-state"></slot>
    <registry-list
      v-else
      :hidden-delete="true"
      :is-loading="isLoading"
      :items="items"
      :pagination="pageInfo"
      @prev-page="prevPage"
      @next-page="nextPage"
    >
      <template #default="{ item }">
        <slot name="item" :item="item"></slot>
      </template>
    </registry-list>
  </div>
</template>

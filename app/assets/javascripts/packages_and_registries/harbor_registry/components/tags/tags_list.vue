<script>
import { GlEmptyState } from '@gitlab/ui';
import RegistryList from '~/packages_and_registries/shared/components/registry_list.vue';
import TagsLoader from '~/packages_and_registries/shared/components/tags_loader.vue';
import TagsListRow from '~/packages_and_registries/harbor_registry/components/tags/tags_list_row.vue';
import {
  NO_ARTIFACTS_TITLE,
  NO_TAGS_MATCHING_FILTERS_TITLE,
  NO_TAGS_MATCHING_FILTERS_DESCRIPTION,
} from '~/packages_and_registries/harbor_registry/constants';

export default {
  name: 'TagsList',
  components: {
    GlEmptyState,
    TagsLoader,
    TagsListRow,
    RegistryList,
  },
  inject: ['noContainersImage'],
  props: {
    tags: {
      type: Array,
      required: true,
    },
    pageInfo: {
      type: Object,
      required: true,
    },
    isLoading: {
      type: Boolean,
      default: false,
      required: false,
    },
  },
  computed: {
    hasNoTags() {
      return this.tags.length === 0;
    },
    emptyStateTitle() {
      return this.filter ? NO_TAGS_MATCHING_FILTERS_TITLE : NO_ARTIFACTS_TITLE;
    },
    emptyStateDescription() {
      return this.filter ? NO_TAGS_MATCHING_FILTERS_DESCRIPTION : '';
    },
  },
  methods: {
    fetchNextPage() {
      this.$emit('next-page');
    },
    fetchPreviousPage() {
      this.$emit('prev-page');
    },
  },
};
</script>

<template>
  <div>
    <tags-loader v-if="isLoading" />
    <gl-empty-state
      v-else-if="hasNoTags"
      :title="emptyStateTitle"
      :svg-path="noContainersImage"
      :svg-height="null"
      :description="emptyStateDescription"
      class="gl-mx-auto gl-my-0"
    />
    <registry-list
      v-else
      :pagination="pageInfo"
      :items="tags"
      hidden-delete
      id-property="name"
      @prev-page="fetchPreviousPage"
      @next-page="fetchNextPage"
    >
      <template #default="{ item }">
        <tags-list-row :tag="item" />
      </template>
    </registry-list>
  </div>
</template>

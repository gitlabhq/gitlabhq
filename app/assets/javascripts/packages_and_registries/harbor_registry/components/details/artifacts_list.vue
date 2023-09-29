<script>
import { GlEmptyState } from '@gitlab/ui';
import RegistryList from '~/packages_and_registries/shared/components/registry_list.vue';
import TagsLoader from '~/packages_and_registries/shared/components/tags_loader.vue';
import {
  NO_ARTIFACTS_TITLE,
  NO_TAGS_MATCHING_FILTERS_TITLE,
  NO_TAGS_MATCHING_FILTERS_DESCRIPTION,
} from '~/packages_and_registries/harbor_registry/constants';
import ArtifactsListRow from '~/packages_and_registries/harbor_registry/components/details/artifacts_list_row.vue';

export default {
  name: 'TagsList',
  components: {
    GlEmptyState,
    ArtifactsListRow,
    TagsLoader,
    RegistryList,
  },
  inject: ['noContainersImage'],
  props: {
    artifacts: {
      type: Array,
      required: true,
    },
    filter: {
      type: String,
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
  data() {
    return {
      tags: [],
      tagsPageInfo: {},
    };
  },
  computed: {
    hasNoTags() {
      return this.artifacts.length === 0;
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
    <template v-else>
      <gl-empty-state
        v-if="hasNoTags"
        :title="emptyStateTitle"
        :svg-path="noContainersImage"
        :svg-height="null"
        :description="emptyStateDescription"
        class="gl-mx-auto gl-my-0"
      />
      <template v-else>
        <registry-list
          :pagination="pageInfo"
          :items="artifacts"
          :hidden-delete="true"
          id-property="name"
          @prev-page="fetchPreviousPage"
          @next-page="fetchNextPage"
        >
          <template #default="{ item }">
            <artifacts-list-row :artifact="item" />
          </template>
        </registry-list>
      </template>
    </template>
  </div>
</template>

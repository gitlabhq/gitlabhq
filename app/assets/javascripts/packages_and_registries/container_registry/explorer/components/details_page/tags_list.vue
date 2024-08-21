<script>
import { GlEmptyState } from '@gitlab/ui';
import { createAlert } from '~/alert';
import { n__ } from '~/locale';
import { fetchPolicies } from '~/lib/graphql';
import { joinPaths } from '~/lib/utils/url_utility';
import Tracking from '~/tracking';
import RegistryList from '~/packages_and_registries/shared/components/registry_list.vue';
import PersistedPagination from '~/packages_and_registries/shared/components/persisted_pagination.vue';
import PersistedSearch from '~/packages_and_registries/shared/components/persisted_search.vue';
import TagsLoader from '~/packages_and_registries/shared/components/tags_loader.vue';
import { FILTERED_SEARCH_TERM } from '~/vue_shared/components/filtered_search_bar/constants';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import {
  ALERT_SUCCESS_TAG,
  ALERT_DANGER_TAG,
  ALERT_SUCCESS_TAGS,
  ALERT_DANGER_TAGS,
  REMOVE_TAGS_BUTTON_TITLE,
  TAGS_LIST_TITLE,
  GRAPHQL_PAGE_SIZE,
  GRAPHQL_PAGE_SIZE_METADATA_ENABLED,
  FETCH_IMAGES_LIST_ERROR_MESSAGE,
  NAME_SORT_FIELD,
  PUBLISHED_SORT_FIELD,
  NO_TAGS_TITLE,
  NO_TAGS_MESSAGE,
  NO_TAGS_MATCHING_FILTERS_TITLE,
  NO_TAGS_MATCHING_FILTERS_DESCRIPTION,
} from '../../constants/index';
import getContainerRepositoryTagsQuery from '../../graphql/queries/get_container_repository_tags.query.graphql';
import deleteContainerRepositoryTagsMutation from '../../graphql/mutations/delete_container_repository_tags.mutation.graphql';
import DeleteModal from '../delete_modal.vue';
import { getPageParams, getNextPageParams, getPreviousPageParams } from '../../utils';
import TagsListRow from './tags_list_row.vue';

export default {
  name: 'TagsList',
  components: {
    DeleteModal,
    GlEmptyState,
    TagsListRow,
    TagsLoader,
    RegistryList,
    PersistedPagination,
    PersistedSearch,
  },
  mixins: [Tracking.mixin(), glFeatureFlagsMixin()],
  inject: ['config'],
  props: {
    id: {
      type: [Number, String],
      required: true,
    },
    isMobile: {
      type: Boolean,
      default: true,
      required: false,
    },
    disabled: {
      type: Boolean,
      default: false,
      required: false,
    },
    isImageLoading: {
      type: Boolean,
      default: false,
      required: false,
    },
  },
  i18n: {
    REMOVE_TAGS_BUTTON_TITLE,
    TAGS_LIST_TITLE,
  },
  apollo: {
    containerRepository: {
      query: getContainerRepositoryTagsQuery,
      fetchPolicy: fetchPolicies.CACHE_AND_NETWORK,
      skip() {
        return !this.sort;
      },
      variables() {
        return this.queryVariables;
      },
      error() {
        createAlert({ message: FETCH_IMAGES_LIST_ERROR_MESSAGE });
      },
    },
  },
  data() {
    return {
      containerRepository: {},
      filters: {},
      itemsToBeDeleted: [],
      isDeleteInProgress: false,
      sort: null,
      pageParams: {},
    };
  },
  computed: {
    defaultSort() {
      return this.config.isMetadataDatabaseEnabled ? 'desc' : 'asc';
    },
    sortableFields() {
      const fields = this.config.isMetadataDatabaseEnabled ? [PUBLISHED_SORT_FIELD] : [];
      return fields.concat(NAME_SORT_FIELD);
    },
    listTitle() {
      return n__('%d tag', '%d tags', this.tags.length);
    },
    tags() {
      return this.containerRepository?.tags?.nodes || [];
    },
    hideBulkDelete() {
      return !this.containerRepository?.userPermissions.destroyContainerRepository;
    },
    tagsPageInfo() {
      return this.containerRepository?.tags?.pageInfo;
    },
    pageSize() {
      return this.config.isMetadataDatabaseEnabled
        ? GRAPHQL_PAGE_SIZE_METADATA_ENABLED
        : GRAPHQL_PAGE_SIZE;
    },
    queryVariables() {
      return {
        id: joinPaths(this.config.gidPrefix, `${this.id}`),
        first: this.pageSize,
        name: this.filters?.name,
        sort: this.sort,
        referrers: this.glFeatures.showContainerRegistryTagSignatures,
        ...this.pageParams,
      };
    },
    hasNoTags() {
      return this.tags.length === 0;
    },
    isLoading() {
      return (
        this.isImageLoading ||
        this.$apollo.queries.containerRepository.loading ||
        this.isDeleteInProgress ||
        !this.sort
      );
    },
    hasFilters() {
      return this.filters?.name;
    },
    emptyStateTitle() {
      return this.hasFilters ? NO_TAGS_MATCHING_FILTERS_TITLE : NO_TAGS_TITLE;
    },
    emptyStateDescription() {
      return this.hasFilters ? NO_TAGS_MATCHING_FILTERS_DESCRIPTION : NO_TAGS_MESSAGE;
    },
    tracking() {
      return {
        label:
          this.itemsToBeDeleted?.length > 1 ? 'bulk_registry_tag_delete' : 'registry_tag_delete',
      };
    },
  },
  methods: {
    deleteTags(toBeDeleted) {
      this.itemsToBeDeleted = toBeDeleted;
      this.track('click_button');
      this.$refs.deleteModal.show();
    },
    confirmDelete() {
      this.handleDeleteTag();
    },
    async handleDeleteTag() {
      this.track('confirm_delete');
      const { itemsToBeDeleted } = this;
      this.isDeleteInProgress = true;
      try {
        const { data } = await this.$apollo.mutate({
          mutation: deleteContainerRepositoryTagsMutation,
          variables: {
            id: this.queryVariables.id,
            tagNames: itemsToBeDeleted.map((item) => item.name),
          },
          awaitRefetchQueries: true,
          refetchQueries: [
            {
              query: getContainerRepositoryTagsQuery,
              variables: this.queryVariables,
            },
          ],
        });
        if (data?.destroyContainerRepositoryTags?.errors[0]) {
          throw new Error();
        }
        this.$emit(
          'delete',
          itemsToBeDeleted.length === 1 ? ALERT_SUCCESS_TAG : ALERT_SUCCESS_TAGS,
        );
        this.itemsToBeDeleted = [];
      } catch (e) {
        this.$emit('delete', itemsToBeDeleted.length === 1 ? ALERT_DANGER_TAG : ALERT_DANGER_TAGS);
      } finally {
        this.isDeleteInProgress = false;
      }
    },
    fetchNextPage() {
      this.pageParams = getNextPageParams(this.tagsPageInfo?.endCursor, this.pageSize);
    },
    fetchPreviousPage() {
      this.pageParams = getPreviousPageParams(this.tagsPageInfo?.startCursor, this.pageSize);
    },
    handleSearchUpdate({ sort, filters, pageInfo }) {
      this.pageParams = getPageParams(pageInfo, this.pageSize);
      this.sort = sort;

      // This takes in account the fact that we will be adding more filters types
      // this is why is an object and not an array or a simple string
      this.filters = filters
        .filter((filter) => filter.value?.data)
        .reduce((acc, filter) => {
          if (filter.type === FILTERED_SEARCH_TERM) {
            return {
              ...acc,
              name: filter.value.data.trim(),
            };
          }
          return acc;
        }, {});
    },
  },
};
</script>

<template>
  <div>
    <persisted-search
      :sortable-fields="sortableFields"
      :default-order="sortableFields[0].orderBy"
      :default-sort="defaultSort"
      @update="handleSearchUpdate"
    />
    <tags-loader v-if="isLoading" />
    <template v-else>
      <gl-empty-state
        v-if="hasNoTags"
        :title="emptyStateTitle"
        :svg-path="config.noContainersImage"
        :svg-height="null"
        :description="emptyStateDescription"
        class="gl-mx-auto gl-my-0"
      />
      <template v-else>
        <registry-list
          :hidden-delete="hideBulkDelete"
          :title="listTitle"
          :items="tags"
          id-property="name"
          @delete="deleteTags"
        >
          <template #default="{ selectItem, isSelected, item, first }">
            <tags-list-row
              :tag="item"
              :first="first"
              :selected="isSelected(item)"
              :is-mobile="isMobile"
              :disabled="disabled"
              @select="selectItem(item)"
              @delete="deleteTags([item])"
            />
          </template>
        </registry-list>

        <delete-modal
          ref="deleteModal"
          :items-to-be-deleted="itemsToBeDeleted"
          @confirmDelete="confirmDelete"
          @cancel="track('cancel_delete')"
        />
      </template>
    </template>

    <div v-if="!isDeleteInProgress" class="gl-flex gl-justify-center">
      <persisted-pagination
        class="gl-mt-3"
        :pagination="tagsPageInfo"
        @prev="fetchPreviousPage"
        @next="fetchNextPage"
      />
    </div>
  </div>
</template>

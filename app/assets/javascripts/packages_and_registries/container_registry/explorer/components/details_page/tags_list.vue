<script>
import { GlEmptyState } from '@gitlab/ui';
import { createAlert } from '~/alert';
import { n__ } from '~/locale';
import { joinPaths } from '~/lib/utils/url_utility';
import Tracking from '~/tracking';
import RegistryList from '~/packages_and_registries/shared/components/registry_list.vue';
import PersistedSearch from '~/packages_and_registries/shared/components/persisted_search.vue';
import TagsLoader from '~/packages_and_registries/shared/components/tags_loader.vue';
import { FILTERED_SEARCH_TERM } from '~/vue_shared/components/filtered_search_bar/constants';
import {
  ALERT_SUCCESS_TAG,
  ALERT_DANGER_TAG,
  ALERT_SUCCESS_TAGS,
  ALERT_DANGER_TAGS,
  REMOVE_TAGS_BUTTON_TITLE,
  TAGS_LIST_TITLE,
  GRAPHQL_PAGE_SIZE,
  FETCH_IMAGES_LIST_ERROR_MESSAGE,
  NAME_SORT_FIELD,
  NO_TAGS_TITLE,
  NO_TAGS_MESSAGE,
  NO_TAGS_MATCHING_FILTERS_TITLE,
  NO_TAGS_MATCHING_FILTERS_DESCRIPTION,
} from '../../constants/index';
import getContainerRepositoryTagsQuery from '../../graphql/queries/get_container_repository_tags.query.graphql';
import deleteContainerRepositoryTagsMutation from '../../graphql/mutations/delete_container_repository_tags.mutation.graphql';
import DeleteModal from '../delete_modal.vue';
import TagsListRow from './tags_list_row.vue';

export default {
  name: 'TagsList',
  components: {
    DeleteModal,
    GlEmptyState,
    TagsListRow,
    TagsLoader,
    RegistryList,
    PersistedSearch,
  },
  mixins: [Tracking.mixin()],
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
  searchConfig: { NAME_SORT_FIELD },
  i18n: {
    REMOVE_TAGS_BUTTON_TITLE,
    TAGS_LIST_TITLE,
  },
  apollo: {
    containerRepository: {
      query: getContainerRepositoryTagsQuery,
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
      mutationLoading: false,
      sort: null,
    };
  },
  computed: {
    listTitle() {
      return n__('%d tag', '%d tags', this.tags.length);
    },
    tags() {
      return this.containerRepository?.tags?.nodes || [];
    },
    hideBulkDelete() {
      return !this.containerRepository?.canDelete;
    },
    tagsPageInfo() {
      return this.containerRepository?.tags?.pageInfo;
    },
    queryVariables() {
      return {
        id: joinPaths(this.config.gidPrefix, `${this.id}`),
        first: GRAPHQL_PAGE_SIZE,
        name: this.filters?.name,
        sort: this.sort,
      };
    },
    hasNoTags() {
      return this.tags.length === 0;
    },
    isLoading() {
      return (
        this.isImageLoading ||
        this.$apollo.queries.containerRepository.loading ||
        this.mutationLoading ||
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
      this.mutationLoading = true;
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
        this.mutationLoading = false;
      }
    },
    fetchNextPage() {
      this.$apollo.queries.containerRepository.fetchMore({
        variables: {
          after: this.tagsPageInfo?.endCursor,
          first: GRAPHQL_PAGE_SIZE,
        },
      });
    },
    fetchPreviousPage() {
      this.$apollo.queries.containerRepository.fetchMore({
        variables: {
          first: null,
          before: this.tagsPageInfo?.startCursor,
          last: GRAPHQL_PAGE_SIZE,
        },
      });
    },
    handleSearchUpdate({ sort, filters }) {
      this.sort = sort;

      const parsed = {
        name: '',
      };

      // This takes in account the fact that we will be adding more filters types
      // this is why is an object and not an array or a simple string
      this.filters = filters.reduce((acc, filter) => {
        if (filter.type === FILTERED_SEARCH_TERM) {
          return {
            ...acc,
            name: `${acc.name} ${filter.value.data}`.trim(),
          };
        }
        return acc;
      }, parsed);
    },
  },
};
</script>

<template>
  <div>
    <persisted-search
      class="gl-mb-5"
      :sortable-fields="/* eslint-disable @gitlab/vue-no-new-non-primitive-in-template */ [
        $options.searchConfig.NAME_SORT_FIELD,
      ] /* eslint-enable @gitlab/vue-no-new-non-primitive-in-template */"
      :default-order="$options.searchConfig.NAME_SORT_FIELD.orderBy"
      default-sort="asc"
      @update="handleSearchUpdate"
    />
    <tags-loader v-if="isLoading" />
    <template v-else>
      <gl-empty-state
        v-if="hasNoTags"
        :title="emptyStateTitle"
        :svg-path="config.noContainersImage"
        :description="emptyStateDescription"
        class="gl-mx-auto gl-my-0"
      />
      <template v-else>
        <registry-list
          :hidden-delete="hideBulkDelete"
          :title="listTitle"
          :pagination="tagsPageInfo"
          :items="tags"
          id-property="name"
          @prev-page="fetchPreviousPage"
          @next-page="fetchNextPage"
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
  </div>
</template>

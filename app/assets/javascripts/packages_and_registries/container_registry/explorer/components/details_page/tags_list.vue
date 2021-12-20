<script>
import createFlash from '~/flash';
import { n__ } from '~/locale';
import { joinPaths } from '~/lib/utils/url_utility';
import RegistryList from '~/packages_and_registries/shared/components/registry_list.vue';
import {
  REMOVE_TAGS_BUTTON_TITLE,
  TAGS_LIST_TITLE,
  GRAPHQL_PAGE_SIZE,
  FETCH_IMAGES_LIST_ERROR_MESSAGE,
} from '../../constants/index';
import getContainerRepositoryTagsQuery from '../../graphql/queries/get_container_repository_tags.query.graphql';
import EmptyState from './empty_state.vue';
import TagsListRow from './tags_list_row.vue';
import TagsLoader from './tags_loader.vue';

export default {
  name: 'TagsList',
  components: {
    TagsListRow,
    EmptyState,
    TagsLoader,
    RegistryList,
  },
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
      variables() {
        return this.queryVariables;
      },
      error() {
        createFlash({ message: FETCH_IMAGES_LIST_ERROR_MESSAGE });
      },
    },
  },
  data() {
    return {
      containerRepository: {},
    };
  },
  computed: {
    listTitle() {
      return n__('%d tag', '%d tags', this.tags.length);
    },
    tags() {
      return this.containerRepository?.tags?.nodes || [];
    },
    tagsPageInfo() {
      return this.containerRepository?.tags?.pageInfo;
    },
    queryVariables() {
      return {
        id: joinPaths(this.config.gidPrefix, `${this.id}`),
        first: GRAPHQL_PAGE_SIZE,
      };
    },
    showMultiDeleteButton() {
      return this.tags.some((tag) => tag.canDelete) && !this.isMobile;
    },
    hasNoTags() {
      return this.tags.length === 0;
    },
    isLoading() {
      return this.isImageLoading || this.$apollo.queries.containerRepository.loading;
    },
  },
  methods: {
    fetchNextPage() {
      this.$apollo.queries.containerRepository.fetchMore({
        variables: {
          after: this.tagsPageInfo?.endCursor,
          first: GRAPHQL_PAGE_SIZE,
        },
        updateQuery(_, { fetchMoreResult }) {
          return fetchMoreResult;
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
        updateQuery(_, { fetchMoreResult }) {
          return fetchMoreResult;
        },
      });
    },
  },
};
</script>

<template>
  <div>
    <tags-loader v-if="isLoading" />
    <template v-else>
      <empty-state v-if="hasNoTags" :no-containers-image="config.noContainersImage" />
      <template v-else>
        <registry-list
          :title="listTitle"
          :pagination="tagsPageInfo"
          :items="tags"
          id-property="name"
          @prev-page="fetchPreviousPage"
          @next-page="fetchNextPage"
          @delete="$emit('delete', $event)"
        >
          <template #default="{ selectItem, isSelected, item, first }">
            <tags-list-row
              :tag="item"
              :first="first"
              :selected="isSelected(item)"
              :is-mobile="isMobile"
              :disabled="disabled"
              @select="selectItem(item)"
              @delete="$emit('delete', [item])"
            />
          </template>
        </registry-list>
      </template>
    </template>
  </div>
</template>

<script>
import { GlButton, GlKeysetPagination } from '@gitlab/ui';
import createFlash from '~/flash';
import { joinPaths } from '~/lib/utils/url_utility';
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
    GlButton,
    GlKeysetPagination,
    TagsListRow,
    EmptyState,
    TagsLoader,
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
      selectedItems: {},
      containerRepository: {},
    };
  },
  computed: {
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
    hasSelectedItems() {
      return this.tags.some((tag) => this.selectedItems[tag.name]);
    },
    showMultiDeleteButton() {
      return this.tags.some((tag) => tag.canDelete) && !this.isMobile;
    },
    multiDeleteButtonIsDisabled() {
      return !this.hasSelectedItems || this.disabled;
    },
    showPagination() {
      return this.tagsPageInfo.hasPreviousPage || this.tagsPageInfo.hasNextPage;
    },
    hasNoTags() {
      return this.tags.length === 0;
    },
    isLoading() {
      return this.isImageLoading || this.$apollo.queries.containerRepository.loading;
    },
  },
  methods: {
    updateSelectedItems(name) {
      this.$set(this.selectedItems, name, !this.selectedItems[name]);
    },
    mapTagsToBeDleeted(items) {
      return this.tags.filter((tag) => items[tag.name]);
    },
    fetchNextPage() {
      this.$apollo.queries.containerRepository.fetchMore({
        variables: {
          after: this.tagsPageInfo?.endCursor,
          first: GRAPHQL_PAGE_SIZE,
        },
        updateQuery(previousResult, { fetchMoreResult }) {
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
        updateQuery(previousResult, { fetchMoreResult }) {
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
        <div class="gl-display-flex gl-justify-content-space-between gl-mb-3">
          <h5 data-testid="list-title">
            {{ $options.i18n.TAGS_LIST_TITLE }}
          </h5>

          <gl-button
            v-if="showMultiDeleteButton"
            :disabled="multiDeleteButtonIsDisabled"
            category="secondary"
            variant="danger"
            @click="$emit('delete', mapTagsToBeDleeted(selectedItems))"
          >
            {{ $options.i18n.REMOVE_TAGS_BUTTON_TITLE }}
          </gl-button>
        </div>
        <tags-list-row
          v-for="(tag, index) in tags"
          :key="tag.path"
          :tag="tag"
          :first="index === 0"
          :selected="selectedItems[tag.name]"
          :is-mobile="isMobile"
          :disabled="disabled"
          @select="updateSelectedItems(tag.name)"
          @delete="$emit('delete', mapTagsToBeDleeted({ [tag.name]: true }))"
        />
        <div class="gl-display-flex gl-justify-content-center">
          <gl-keyset-pagination
            v-if="showPagination"
            :has-next-page="tagsPageInfo.hasNextPage"
            :has-previous-page="tagsPageInfo.hasPreviousPage"
            class="gl-mt-3"
            @prev="fetchPreviousPage"
            @next="fetchNextPage"
          />
        </div>
      </template>
    </template>
  </div>
</template>

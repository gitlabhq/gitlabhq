<script>
import { GlFilteredSearchToken } from '@gitlab/ui';
import {
  NAME_SORT_FIELD,
  ROOT_IMAGE_TEXT,
  DEFAULT_PER_PAGE,
  FETCH_ARTIFACT_LIST_ERROR_MESSAGE,
  TOKEN_TYPE_TAG_NAME,
  TAG_LABEL,
} from '~/packages_and_registries/harbor_registry/constants/index';
import { OPERATORS_IS } from '~/vue_shared/components/filtered_search_bar/constants';
import { createAlert } from '~/alert';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import TagsLoader from '~/packages_and_registries/shared/components/tags_loader.vue';
import ArtifactsList from '~/packages_and_registries/harbor_registry/components/details/artifacts_list.vue';
import PersistedSearch from '~/packages_and_registries/shared/components/persisted_search.vue';
import DetailsHeader from '~/packages_and_registries/harbor_registry/components/details/details_header.vue';
import {
  extractSortingDetail,
  parseFilter,
  formatPagination,
} from '~/packages_and_registries/harbor_registry/utils';
import { getHarborArtifacts } from '~/rest_api';

export default {
  name: 'HarborDetailsPage',
  components: {
    ArtifactsList,
    TagsLoader,
    DetailsHeader,
    PersistedSearch,
  },
  inject: ['endpoint', 'breadCrumbState'],
  searchConfig: { nameSortFields: [NAME_SORT_FIELD] },
  tokens: [
    {
      type: TOKEN_TYPE_TAG_NAME,
      icon: 'tag',
      title: TAG_LABEL,
      unique: true,
      token: GlFilteredSearchToken,
      operators: OPERATORS_IS,
    },
  ],
  data() {
    return {
      artifactsList: [],
      pageInfo: {},
      mutationLoading: false,
      deleteAlertType: null,
      isLoading: true,
      filterString: '',
      sorting: null,
    };
  },
  computed: {
    currentPage() {
      return this.pageInfo.page || 1;
    },
    imagesDetail() {
      return {
        name: this.fullName,
        artifactCount: this.pageInfo?.total || 0,
      };
    },
    fullName() {
      const { project, image } = this.$route.params;

      if (project && image) {
        return `${project}/${image}`;
      }
      return '';
    },
  },
  mounted() {
    this.updateBreadcrumb();
  },
  methods: {
    updateBreadcrumb() {
      const name = this.fullName || ROOT_IMAGE_TEXT;
      this.breadCrumbState.updateName(name);
      this.breadCrumbState.updateHref(this.$route.path);
    },
    handleSearchUpdate({ sort, filters }) {
      this.sorting = sort;
      this.filterString = parseFilter(filters, 'digest');

      this.fetchArtifacts(1);
    },
    fetchPrevPage() {
      const prevPageNum = this.currentPage - 1;
      this.fetchArtifacts(prevPageNum);
    },
    fetchNextPage() {
      const nextPageNum = this.currentPage + 1;
      this.fetchArtifacts(nextPageNum);
    },
    fetchArtifacts(requestPage) {
      this.isLoading = true;

      const { orderBy, sort } = extractSortingDetail(this.sorting);
      const sortOptions = `${orderBy} ${sort}`;

      const { image } = this.$route.params;

      const params = {
        requestPath: this.endpoint,
        repoName: image,
        limit: DEFAULT_PER_PAGE,
        page: requestPage,
        sort: sortOptions,
        search: this.filterString,
      };

      getHarborArtifacts(params)
        .then((res) => {
          this.pageInfo = formatPagination(res.headers);

          this.artifactsList = (res?.data || []).map((artifact) => {
            return convertObjectPropsToCamelCase(artifact);
          });
        })
        .catch(() => {
          createAlert({ message: FETCH_ARTIFACT_LIST_ERROR_MESSAGE });
        })
        .finally(() => {
          this.isLoading = false;
        });
    },
  },
};
</script>

<template>
  <div class="gl-my-3">
    <details-header :images-detail="imagesDetail" />
    <persisted-search
      :sortable-fields="$options.searchConfig.nameSortFields"
      :default-order="$options.searchConfig.nameSortFields[0].orderBy"
      default-sort="asc"
      :tokens="$options.tokens"
      @update="handleSearchUpdate"
    />
    <tags-loader v-if="isLoading" />
    <artifacts-list
      v-else
      :filter="filterString"
      :is-loading="isLoading"
      :artifacts="artifactsList"
      :page-info="pageInfo"
      @prev-page="fetchPrevPage"
      @next-page="fetchNextPage"
    />
  </div>
</template>

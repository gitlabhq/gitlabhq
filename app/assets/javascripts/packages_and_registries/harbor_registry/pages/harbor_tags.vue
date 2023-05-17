<script>
import TagsHeader from '~/packages_and_registries/harbor_registry/components/tags/tags_header.vue';
import TagsList from '~/packages_and_registries/harbor_registry/components/tags/tags_list.vue';
import { getHarborTags } from '~/rest_api';
import { FETCH_TAGS_ERROR_MESSAGE } from '~/packages_and_registries/harbor_registry/constants';
import { convertObjectPropsToCamelCase } from '~/lib/utils/common_utils';
import { createAlert } from '~/alert';
import { formatPagination } from '~/packages_and_registries/harbor_registry/utils';

export default {
  name: 'HarborTagsPage',
  components: {
    TagsHeader,
    TagsList,
  },
  inject: ['endpoint', 'breadCrumbState'],
  data() {
    return {
      tagsLoading: false,
      pageInfo: {},
      tags: [],
    };
  },
  computed: {
    currentPage() {
      return this.pageInfo?.page || 1;
    },
    artifactDetail() {
      const { project, image, digest } = this.$route.params;

      return {
        project,
        image,
        digest,
      };
    },
  },
  mounted() {
    this.updateBreadcrumb();
    this.fetchTagsData();
  },
  methods: {
    updateBreadcrumb() {
      const artifactPath = `${this.artifactDetail.project}/${this.artifactDetail.image}`;
      const nameList = [artifactPath, this.artifactDetail.digest];
      const hrefList = [`/${artifactPath}`, this.$route.path];

      this.breadCrumbState.updateName(nameList);
      this.breadCrumbState.updateHref(hrefList);
    },
    fetchPrevPage() {
      const prevPageNum = this.currentPage - 1;
      this.fetchTagsData(prevPageNum);
    },
    fetchNextPage() {
      const nextPageNum = this.currentPage + 1;
      this.fetchTagsData(nextPageNum);
    },
    fetchTagsData(requestPage) {
      this.tagsLoading = true;

      const params = {
        page: requestPage,
        requestPath: this.endpoint,
        repoName: this.artifactDetail.image,
        digest: this.artifactDetail.digest,
      };

      getHarborTags(params)
        .then((res) => {
          this.pageInfo = formatPagination(res.headers);

          this.tags = (res?.data || []).map((tagInfo) => {
            return convertObjectPropsToCamelCase(tagInfo);
          });
        })
        .catch(() => {
          createAlert({ message: FETCH_TAGS_ERROR_MESSAGE });
        })
        .finally(() => {
          this.tagsLoading = false;
        });
    },
  },
};
</script>

<template>
  <div>
    <tags-header
      :artifact-detail="artifactDetail"
      :page-info="pageInfo"
      :tags-loading="tagsLoading"
    />
    <tags-list
      :tags="tags"
      :is-loading="tagsLoading"
      :page-info="pageInfo"
      @prev-page="fetchPrevPage"
      @next-page="fetchNextPage"
    />
  </div>
</template>

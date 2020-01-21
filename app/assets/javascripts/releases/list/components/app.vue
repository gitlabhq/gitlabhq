<script>
import { mapState, mapActions } from 'vuex';
import { GlSkeletonLoading, GlEmptyState } from '@gitlab/ui';
import {
  getParameterByName,
  historyPushState,
  buildUrlWithCurrentLocation,
} from '~/lib/utils/common_utils';
import TablePagination from '~/vue_shared/components/pagination/table_pagination.vue';
import ReleaseBlock from './release_block.vue';

export default {
  name: 'ReleasesApp',
  components: {
    GlSkeletonLoading,
    GlEmptyState,
    ReleaseBlock,
    TablePagination,
  },
  props: {
    projectId: {
      type: String,
      required: true,
    },
    documentationLink: {
      type: String,
      required: true,
    },
    illustrationPath: {
      type: String,
      required: true,
    },
  },
  computed: {
    ...mapState(['isLoading', 'releases', 'hasError', 'pageInfo']),
    shouldRenderEmptyState() {
      return !this.releases.length && !this.hasError && !this.isLoading;
    },
    shouldRenderSuccessState() {
      return this.releases.length && !this.isLoading && !this.hasError;
    },
  },
  created() {
    this.fetchReleases({
      page: getParameterByName('page'),
      projectId: this.projectId,
    });
  },
  methods: {
    ...mapActions(['fetchReleases']),
    onChangePage(page) {
      historyPushState(buildUrlWithCurrentLocation(`?page=${page}`));
      this.fetchReleases({ page, projectId: this.projectId });
    },
  },
};
</script>
<template>
  <div class="prepend-top-default">
    <gl-skeleton-loading v-if="isLoading" class="js-loading" />

    <gl-empty-state
      v-else-if="shouldRenderEmptyState"
      class="js-empty-state"
      :title="__('Getting started with releases')"
      :svg-path="illustrationPath"
      :description="
        __(
          'Releases are based on Git tags and mark specific points in a project\'s development history. They can contain information about the type of changes and can also deliver binaries, like compiled versions of your software.',
        )
      "
      :primary-button-link="documentationLink"
      :primary-button-text="__('Open Documentation')"
    />

    <div v-else-if="shouldRenderSuccessState" class="js-success-state">
      <release-block
        v-for="(release, index) in releases"
        :key="release.tag_name"
        :release="release"
        :class="{ 'linked-card': releases.length > 1 && index !== releases.length - 1 }"
      />
    </div>

    <table-pagination v-if="!isLoading" :change="onChangePage" :page-info="pageInfo" />
  </div>
</template>
<style>
.linked-card::after {
  width: 1px;
  content: ' ';
  border: 1px solid #e5e5e5;
  height: 17px;
  top: 100%;
  position: absolute;
  left: 32px;
}
</style>

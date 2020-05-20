<script>
import { mapState, mapActions } from 'vuex';
import { GlSkeletonLoading, GlEmptyState, GlLink, GlButton } from '@gitlab/ui';
import {
  getParameterByName,
  historyPushState,
  buildUrlWithCurrentLocation,
} from '~/lib/utils/common_utils';
import { __ } from '~/locale';
import TablePagination from '~/vue_shared/components/pagination/table_pagination.vue';
import ReleaseBlock from './release_block.vue';

export default {
  name: 'ReleasesApp',
  components: {
    GlSkeletonLoading,
    GlEmptyState,
    ReleaseBlock,
    TablePagination,
    GlLink,
    GlButton,
  },
  props: {
    projectId: {
      type: String,
      required: true,
    },
    documentationPath: {
      type: String,
      required: true,
    },
    illustrationPath: {
      type: String,
      required: true,
    },
    newReleasePath: {
      type: String,
      required: false,
      default: '',
    },
  },
  computed: {
    ...mapState('list', ['isLoading', 'releases', 'hasError', 'pageInfo']),
    shouldRenderEmptyState() {
      return !this.releases.length && !this.hasError && !this.isLoading;
    },
    shouldRenderSuccessState() {
      return this.releases.length && !this.isLoading && !this.hasError;
    },
    emptyStateText() {
      return __(
        "Releases are based on Git tags and mark specific points in a project's development history. They can contain information about the type of changes and can also deliver binaries, like compiled versions of your software.",
      );
    },
  },
  created() {
    this.fetchReleases({
      page: getParameterByName('page'),
      projectId: this.projectId,
    });
  },
  methods: {
    ...mapActions('list', ['fetchReleases']),
    onChangePage(page) {
      historyPushState(buildUrlWithCurrentLocation(`?page=${page}`));
      this.fetchReleases({ page, projectId: this.projectId });
    },
  },
};
</script>
<template>
  <div class="flex flex-column mt-2">
    <gl-button
      v-if="newReleasePath"
      :href="newReleasePath"
      :aria-describedby="shouldRenderEmptyState && 'releases-description'"
      category="primary"
      variant="success"
      class="align-self-end mb-2 js-new-release-btn"
    >
      {{ __('New release') }}
    </gl-button>

    <gl-skeleton-loading v-if="isLoading" class="js-loading" />

    <gl-empty-state
      v-else-if="shouldRenderEmptyState"
      class="js-empty-state"
      :title="__('Getting started with releases')"
      :svg-path="illustrationPath"
    >
      <template #description>
        <span id="releases-description">
          {{ emptyStateText }}
          <gl-link
            :href="documentationPath"
            :aria-label="__('Releases documentation')"
            target="_blank"
          >
            {{ __('More information') }}
          </gl-link>
        </span>
      </template>
    </gl-empty-state>

    <div v-else-if="shouldRenderSuccessState" class="js-success-state">
      <release-block
        v-for="(release, index) in releases"
        :key="index"
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

<script>
import { GlEmptyState, GlLink, GlButton } from '@gitlab/ui';
import { mapState, mapActions } from 'vuex';
import { getParameterByName } from '~/lib/utils/url_utility';
import { __ } from '~/locale';
import ReleaseBlock from './release_block.vue';
import ReleaseSkeletonLoader from './release_skeleton_loader.vue';
import ReleasesPagination from './releases_pagination.vue';
import ReleasesSort from './releases_sort.vue';

export default {
  name: 'ReleasesApp',
  components: {
    GlEmptyState,
    GlLink,
    GlButton,
    ReleaseBlock,
    ReleasesPagination,
    ReleaseSkeletonLoader,
    ReleasesSort,
  },
  computed: {
    ...mapState('index', [
      'documentationPath',
      'illustrationPath',
      'newReleasePath',
      'isLoading',
      'releases',
      'hasError',
    ]),
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
    this.fetchReleases();

    window.addEventListener('popstate', this.fetchReleases);
  },
  methods: {
    ...mapActions('index', {
      fetchReleasesStoreAction: 'fetchReleases',
    }),
    fetchReleases() {
      this.fetchReleasesStoreAction({
        before: getParameterByName('before'),
        after: getParameterByName('after'),
      });
    },
  },
};
</script>
<template>
  <div class="flex flex-column mt-2">
    <div class="gl-align-self-end gl-mb-3">
      <releases-sort class="gl-mr-2" @sort:changed="fetchReleases" />

      <gl-button
        v-if="newReleasePath"
        :href="newReleasePath"
        :aria-describedby="shouldRenderEmptyState && 'releases-description'"
        category="primary"
        variant="success"
        data-testid="new-release-button"
      >
        {{ __('New release') }}
      </gl-button>
    </div>

    <release-skeleton-loader v-if="isLoading" />

    <gl-empty-state
      v-else-if="shouldRenderEmptyState"
      data-testid="empty-state"
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

    <div v-else-if="shouldRenderSuccessState" data-testid="success-state">
      <release-block
        v-for="(release, index) in releases"
        :key="index"
        :release="release"
        :class="{ 'linked-card': releases.length > 1 && index !== releases.length - 1 }"
      />
    </div>

    <releases-pagination v-if="!isLoading" />
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

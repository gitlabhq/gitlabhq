<script>
import createFlash from '~/flash';
import { s__ } from '~/locale';
import oneReleaseQuery from '../graphql/queries/one_release.query.graphql';
import { convertGraphQLRelease } from '../util';
import ReleaseBlock from './release_block.vue';
import ReleaseSkeletonLoader from './release_skeleton_loader.vue';

export default {
  name: 'ReleaseShowApp',
  components: {
    ReleaseBlock,
    ReleaseSkeletonLoader,
  },
  inject: {
    fullPath: {
      default: '',
    },
    tagName: {
      default: '',
    },
  },
  apollo: {
    release: {
      query: oneReleaseQuery,
      variables() {
        return {
          fullPath: this.fullPath,
          tagName: this.tagName,
        };
      },
      update(data) {
        if (data.project?.release) {
          return convertGraphQLRelease(data.project.release);
        }

        return null;
      },
      result(result) {
        // Handle the case where the query succeeded but didn't return any data
        if (!result.error && !this.release) {
          this.showFlash(
            new Error(`No release found in project "${this.fullPath}" with tag "${this.tagName}"`),
          );
        }
      },
      error(error) {
        this.showFlash(error);
      },
    },
  },
  methods: {
    showFlash(error) {
      createFlash({
        message: s__('Release|Something went wrong while getting the release details.'),
        captureError: true,
        error,
      });
    },
  },
};
</script>
<template>
  <div class="gl-mt-3">
    <release-skeleton-loader v-if="$apollo.queries.release.loading" />

    <release-block v-else-if="release" :release="release" />
  </div>
</template>

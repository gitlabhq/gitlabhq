<script>
import { GlSprintf, GlLoadingIcon } from '@gitlab/ui';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import { TYPENAME_CONTAINER_REPOSITORY } from '~/graphql_shared/constants';
import DetailsRow from '~/vue_shared/components/registry/details_row.vue';
import { NO_PLATFORMS_AVAILABLE_TEXT, SUPPORTED_PLATFORMS_ROW_TEXT } from '../../constants/index';
import getTagPlatformDetailsQuery from '../../graphql/queries/get_tag_platform_details.query.graphql';
import PlatformBadge from './platform_badge.vue';

export default {
  name: 'PlatformBadgesRow',
  components: { GlSprintf, GlLoadingIcon, DetailsRow, PlatformBadge },
  props: {
    tag: {
      type: Object,
      required: true,
    },
  },
  i18n: {
    NO_PLATFORMS_AVAILABLE_TEXT,
    SUPPORTED_PLATFORMS_ROW_TEXT,
  },
  data() {
    return {
      tagDetails: null,
    };
  },
  apollo: {
    tagDetails: {
      query: getTagPlatformDetailsQuery,
      variables() {
        return {
          id: convertToGraphQLId(TYPENAME_CONTAINER_REPOSITORY, this.$route.params.id),
          tagName: this.tag.name,
        };
      },
      update({ containerRepository }) {
        return containerRepository?.tagDetails ?? null;
      },
      error() {
        this.tagDetails = null;
      },
    },
  },
  computed: {
    tagManifests() {
      const manifests = this.tagDetails?.manifests ?? [];
      return [...manifests]
        .filter((m) => m.platform && m.platform.os && m.platform.architecture)
        .sort((a, b) => {
          for (const field of ['os', 'architecture', 'variant', 'osVersion']) {
            const aVal = a.platform[field] ?? '';
            const bVal = b.platform[field] ?? '';
            if (aVal < bVal) return -1;
            if (aVal > bVal) return 1;
          }
          return 0;
        });
    },
    isLoading() {
      return this.$apollo.queries.tagDetails.loading;
    },
  },
};
</script>

<template>
  <details-row icon="applications" data-testid="manifest-platforms">
    <gl-sprintf :message="$options.i18n.SUPPORTED_PLATFORMS_ROW_TEXT">
      <template #supportedPlatforms>
        <gl-loading-icon v-if="isLoading" inline size="sm" />
        <template v-else>
          <template v-if="tagManifests && tagManifests.length">
            <platform-badge
              v-for="manifest in tagManifests"
              :key="manifest.digest"
              :platform="manifest.platform"
              class="gl-mb-2 gl-mr-2"
            />
          </template>
          <span v-else data-testid="no-platforms-available">{{
            $options.i18n.NO_PLATFORMS_AVAILABLE_TEXT
          }}</span>
        </template>
      </template>
    </gl-sprintf>
  </details-row>
</template>

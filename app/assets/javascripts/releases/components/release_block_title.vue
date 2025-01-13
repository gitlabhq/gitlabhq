<script>
import { GlTooltipDirective, GlLink, GlBadge, GlIcon } from '@gitlab/ui';
import { __ } from '~/locale';
import CiCdCatalogWrapper from './ci_cd_catalog_wrapper.vue';

export default {
  name: 'ReleaseBlockTitle',
  i18n: {
    historical: __('Historical release'),
    historicalTooltip: __(
      'This release was created with a date in the past. Evidence collection at the moment of the release is unavailable.',
    ),
  },
  components: {
    GlLink,
    GlBadge,
    GlIcon,
    CiCdCatalogWrapper,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    release: {
      type: Object,
      required: true,
    },
  },
  computed: {
    selfLink() {
      return this.release._links?.self;
    },
  },
};
</script>

<template>
  <div class="gl-contents">
    <span data-testid="release-name">
      <gl-link v-if="selfLink" class="gl-self-center gl-text-default" :href="selfLink">
        {{ release.name }}
      </gl-link>
      <template v-else>
        <span class="gl-text-default" data-testid="release-block-title">{{ release.name }}</span>
        <gl-icon
          v-gl-tooltip
          name="lock"
          :title="
            __(
              'Private - Guest users are not allowed to view detailed release information like title and source code.',
            )
          "
          variant="subtle"
        />
      </template>
    </span>
    <ci-cd-catalog-wrapper :release-path="release.tagPath">
      <template #default="{ isCatalogRelease, detailsPagePath }">
        <gl-badge
          v-if="isCatalogRelease"
          :href="detailsPagePath"
          variant="info"
          data-testid="catalog-badge"
          >{{ __('CI/CD Catalog') }}</gl-badge
        >
      </template>
    </ci-cd-catalog-wrapper>
    <gl-badge v-if="release.upcomingRelease" variant="warning">
      {{ __('Upcoming Release') }}
    </gl-badge>
    <gl-badge
      v-else-if="release.historicalRelease"
      v-gl-tooltip
      :title="$options.i18n.historicalTooltip"
    >
      {{ $options.i18n.historical }}
    </gl-badge>
  </div>
</template>

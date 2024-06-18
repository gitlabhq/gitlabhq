<script>
import { GlTooltipDirective, GlLink, GlBadge, GlButton, GlIcon } from '@gitlab/ui';
import { setUrlParams } from '~/lib/utils/url_utility';
import { __ } from '~/locale';
import { BACK_URL_PARAM } from '~/releases/constants';

export default {
  i18n: {
    editButton: __('Edit release'),
    historical: __('Historical release'),
    historicalTooltip: __(
      'This release was created with a date in the past. Evidence collection at the moment of the release is unavailable.',
    ),
  },
  name: 'ReleaseBlockHeader',
  components: {
    GlLink,
    GlBadge,
    GlButton,
    GlIcon,
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
    editLink() {
      if (this.release._links?.editUrl) {
        const queryParams = {
          [BACK_URL_PARAM]: window.location.href,
        };

        return setUrlParams(queryParams, this.release._links.editUrl);
      }

      return undefined;
    },
    selfLink() {
      return this.release._links?.self;
    },
  },
};
</script>

<template>
  <div class="gl-flex gl-items-center gl-justify-content-space-between gl-w-full">
    <h2
      class="gl-new-card-title gl-heading-3 gl-m-0! gl-flex gl-gap-3"
      data-testid="release-block-title"
    >
      <gl-link v-if="selfLink" class="gl-text-black-normal" :href="selfLink">
        {{ release.name }}
      </gl-link>
      <template v-else>
        <span class="gl-text-black-normal">{{ release.name }}</span>
        <gl-icon
          v-gl-tooltip
          name="lock"
          :title="
            __(
              'Private - Guest users are not allowed to view detailed release information like title and source code.',
            )
          "
          class="gl-text-secondary"
        />
      </template>
      <gl-badge v-if="release.upcomingRelease" variant="warning" class="gl-align-self-center">{{
        __('Upcoming Release')
      }}</gl-badge>
      <gl-badge
        v-else-if="release.historicalRelease"
        v-gl-tooltip
        :title="$options.i18n.historicalTooltip"
        class="gl-align-self-center"
      >
        {{ $options.i18n.historical }}
      </gl-badge>
    </h2>
    <gl-button
      v-if="editLink"
      category="primary"
      size="small"
      variant="default"
      class="js-edit-button"
      :href="editLink"
    >
      {{ $options.i18n.editButton }}
    </gl-button>
  </div>
</template>

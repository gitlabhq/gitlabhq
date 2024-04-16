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
  <div class="card-header d-flex gl-align-items-center bg-white pr-0">
    <h2 class="card-title gl-my-2 mr-auto gl-font-size-h2">
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
          class="text-secondary gl-mb-2"
        />
      </template>
      <gl-badge v-if="release.upcomingRelease" variant="warning" class="align-middle">{{
        __('Upcoming Release')
      }}</gl-badge>
      <gl-badge
        v-else-if="release.historicalRelease"
        v-gl-tooltip
        :title="$options.i18n.historicalTooltip"
        class="gl-vertical-align-middle"
      >
        {{ $options.i18n.historical }}
      </gl-badge>
    </h2>
    <gl-button
      v-if="editLink"
      category="primary"
      size="small"
      variant="default"
      class="gl-mr-3 js-edit-button gl-ml-3 gl-pb-3"
      :href="editLink"
    >
      {{ $options.i18n.editButton }}
    </gl-button>
  </div>
</template>

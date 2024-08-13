<script>
import { GlTooltipDirective, GlLink, GlBadge, GlIcon } from '@gitlab/ui';
import { __ } from '~/locale';

export default {
  i18n: {
    historical: __('Historical release'),
    historicalTooltip: __(
      'This release was created with a date in the past. Evidence collection at the moment of the release is unavailable.',
    ),
  },
  name: 'ReleaseBlockHeader',
  components: {
    GlLink,
    GlBadge,
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
    selfLink() {
      return this.release._links?.self;
    },
  },
};
</script>

<template>
  <div class="gl-contents">
    <gl-link v-if="selfLink" class="gl-text-default" :href="selfLink">
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
        class="gl-text-secondary"
      />
    </template>
    <gl-badge v-if="release.upcomingRelease" variant="warning" class="gl-self-center">{{
      __('Upcoming Release')
    }}</gl-badge>
    <gl-badge
      v-else-if="release.historicalRelease"
      v-gl-tooltip
      :title="$options.i18n.historicalTooltip"
      class="gl-self-center"
    >
      {{ $options.i18n.historical }}
    </gl-badge>
  </div>
</template>

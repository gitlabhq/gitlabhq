<script>
import { GlTooltipDirective, GlLink, GlBadge, GlButton, GlIcon } from '@gitlab/ui';
import { setUrlParams } from '~/lib/utils/url_utility';
import { __ } from '~/locale';
import { BACK_URL_PARAM } from '~/releases/constants';

export default {
  i18n: {
    editButton: __('Edit this release'),
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
  <div class="card-header d-flex align-items-center bg-white pr-0">
    <h2 class="card-title my-2 mr-auto">
      <gl-link v-if="selfLink" :href="selfLink" class="font-size-inherit">
        {{ release.name }}
      </gl-link>
      <template v-else>
        {{ release.name }}
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
    </h2>
    <gl-button
      v-if="editLink"
      v-gl-tooltip
      category="primary"
      variant="default"
      icon="pencil"
      class="gl-mr-3 js-edit-button ml-2 pb-2"
      :title="$options.i18n.editButton"
      :aria-label="$options.i18n.editButton"
      :href="editLink"
    />
  </div>
</template>

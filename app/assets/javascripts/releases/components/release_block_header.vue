<script>
import { GlTooltipDirective, GlLink, GlBadge } from '@gitlab/ui';
import Icon from '~/vue_shared/components/icon.vue';
import { BACK_URL_PARAM } from '~/releases/constants';
import { setUrlParams } from '~/lib/utils/url_utility';

export default {
  name: 'ReleaseBlockHeader',
  components: {
    GlLink,
    GlBadge,
    Icon,
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
    <h2 class="card-title my-2 mr-auto gl-font-size-20-deprecated-no-really-do-not-use-me">
      <gl-link v-if="selfLink" :href="selfLink" class="font-size-inherit">
        {{ release.name }}
      </gl-link>
      <template v-else>{{ release.name }}</template>
      <gl-badge v-if="release.upcomingRelease" variant="warning" class="align-middle">{{
        __('Upcoming Release')
      }}</gl-badge>
    </h2>
    <gl-link
      v-if="editLink"
      v-gl-tooltip
      class="btn btn-default append-right-10 js-edit-button ml-2"
      :title="__('Edit this release')"
      :href="editLink"
    >
      <icon name="pencil" />
    </gl-link>
  </div>
</template>

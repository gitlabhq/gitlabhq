<script>
import { GlTooltipDirective, GlLink, GlBadge } from '@gitlab/ui';
import Icon from '~/vue_shared/components/icon.vue';

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
      return this.release._links?.edit_url;
    },
    selfLink() {
      return this.release._links?.self;
    },
  },
};
</script>

<template>
  <div class="card-header d-flex align-items-center bg-white pr-0">
    <h2 class="card-title my-2 mr-auto gl-font-size-20">
      <gl-link v-if="selfLink" :href="selfLink" class="font-size-inherit">
        {{ release.name }}
      </gl-link>
      <template v-else>{{ release.name }}</template>
      <gl-badge v-if="release.upcoming_release" variant="warning" class="align-middle">{{
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

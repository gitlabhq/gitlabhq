<script>
import { GlTooltipDirective, GlLink } from '@gitlab/ui';
import Icon from '~/vue_shared/components/icon.vue';

export default {
  name: 'ReleaseBlockAssets',
  components: {
    GlLink,
    Icon,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    assets: {
      type: Object,
      required: true,
    },
  },
  computed: {
    hasAssets() {
      return Boolean(this.assets.count);
    },
  },
};
</script>

<template>
  <div class="card-text prepend-top-default">
    <b>
      {{ __('Assets') }}
      <span class="js-assets-count badge badge-pill">{{ assets.count }}</span>
    </b>

    <ul v-if="assets.links.length" class="pl-0 mb-0 prepend-top-8 list-unstyled js-assets-list">
      <li v-for="link in assets.links" :key="link.name" class="append-bottom-8">
        <gl-link v-gl-tooltip.bottom :title="__('Download asset')" :href="link.url">
          <icon name="package" class="align-middle append-right-4 align-text-bottom" />
          {{ link.name }}
          <span v-if="link.external">{{ __('(external source)') }}</span>
        </gl-link>
      </li>
    </ul>

    <div v-if="hasAssets" class="dropdown">
      <button
        type="button"
        class="btn btn-link"
        data-toggle="dropdown"
        aria-haspopup="true"
        aria-expanded="false"
      >
        <icon name="doc-code" class="align-top append-right-4" />
        {{ __('Source code') }}
        <icon name="arrow-down" />
      </button>

      <div class="js-sources-dropdown dropdown-menu">
        <li v-for="asset in assets.sources" :key="asset.url">
          <gl-link :href="asset.url">{{ __('Download') }} {{ asset.format }}</gl-link>
        </li>
      </div>
    </div>
  </div>
</template>

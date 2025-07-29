<script>
import { GlTooltipDirective } from '@gitlab/ui';
import { __ } from '~/locale';
import SafeHtml from '~/vue_shared/directives/safe_html';
import { hasTouchCapability } from '~/lib/utils/touch_detection';
import logo from '../../../../views/shared/_logo.svg?raw';

export default {
  logo,
  i18n: {
    homepage: __('Homepage'),
  },
  directives: {
    GlTooltip: GlTooltipDirective,
    SafeHtml,
  },
  inject: ['rootPath'],
  props: {
    logoUrl: {
      type: String,
      required: false,
      default: '',
    },
  },
  computed: {
    homepageTooltip() {
      return hasTouchCapability() ? null : this.$options.i18n.homepage;
    },
  },
};
</script>

<template>
  <a
    v-gl-tooltip:super-sidebar.right="homepageTooltip"
    class="brand-logo gl-inline-block gl-rounded-base gl-border-none gl-bg-transparent gl-p-2 focus:gl-focus active:gl-focus"
    :href="rootPath"
    data-track-action="click_link"
    data-track-label="gitlab_logo_link"
    data-track-property="nav_core_menu"
  >
    <span class="gl-sr-only">{{ $options.i18n.homepage }}</span>
    <!-- eslint-disable @gitlab/vue-require-i18n-attribute-strings -->
    <img
      v-if="logoUrl"
      alt=""
      data-testid="brand-header-custom-logo"
      :src="logoUrl"
      class="gl-h-6 gl-max-w-full"
    />
    <!-- eslint-enable @gitlab/vue-require-i18n-attribute-strings -->
    <span
      v-else
      v-safe-html="$options.logo"
      aria-hidden="true"
      data-testid="brand-header-default-logo"
    ></span>
  </a>
</template>

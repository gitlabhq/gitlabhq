<script>
import { GlTooltipDirective } from '@gitlab/ui';
import { __ } from '~/locale';
import SafeHtml from '~/vue_shared/directives/safe_html';
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
};
</script>

<template>
  <a
    v-gl-tooltip:super-sidebar.hover.bottom="$options.i18n.homepage"
    class="tanuki-logo-container"
    :href="rootPath"
    :title="$options.i18n.homepage"
    data-track-action="click_link"
    data-track-label="gitlab_logo_link"
    data-track-property="nav_core_menu"
  >
    <img
      v-if="logoUrl"
      data-testid="brand-header-custom-logo"
      :src="logoUrl"
      class="gl-h-6 gl-max-w-full"
    />
    <span v-else v-safe-html="$options.logo" data-testid="brand-header-default-logo"></span>
  </a>
</template>

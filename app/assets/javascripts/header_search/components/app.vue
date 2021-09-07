<script>
import { GlSearchBoxByType } from '@gitlab/ui';
import { __ } from '~/locale';

export default {
  name: 'HeaderSearchApp',
  i18n: {
    searchPlaceholder: __('Search or jump to...'),
  },
  components: {
    GlSearchBoxByType,
  },
};
</script>

<template>
  <section class="header-search">
    <gl-search-box-by-type autocomplete="off" :placeholder="$options.i18n.searchPlaceholder" />
  </section>
</template>

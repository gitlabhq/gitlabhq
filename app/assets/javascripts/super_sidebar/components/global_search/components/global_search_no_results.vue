<script>
import { NO_SEARCH_RESULTS } from '~/vue_shared/global_search/constants';

export default {
  name: 'GlobalSearchNoResults',
  i18n: {
    NO_SEARCH_RESULTS,
  },
};
</script>

<template>
  <ul class="gl-m-0 gl-list-none gl-p-0">
    <li class="command-palette-px gl-border-t gl-border-t-dropdown gl-py-5 gl-text-default">
      {{ $options.i18n.NO_SEARCH_RESULTS }}
    </li>
  </ul>
</template>

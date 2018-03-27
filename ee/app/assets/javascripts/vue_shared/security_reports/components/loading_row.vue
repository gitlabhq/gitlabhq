<script>
import LoadingIcon from '~/vue_shared/components/loading_icon.vue';

/**
 * Renders the loading row for each security report
 */

export default {
  name: 'SecurityLoadingRow',
  components: {
    LoadingIcon,
  },
};
</script>
<template>
  <div class="report-block-list-issue prepend-left-default append-right-default">
    <div class="report-block-list-icon append-right-10 prepend-left-5">
      <loading-icon />
    </div>
    <div class="report-block-list-issue-description">
      {{ __("in progress") }}
    </div>
  </div>
</template>

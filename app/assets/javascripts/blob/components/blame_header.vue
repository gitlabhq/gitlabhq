<script>
import BlamePreferences from '~/blame/preferences/blame_preferences.vue';

export default {
  components: { BlamePreferences },
  inject: ['hasRevsFile'],
};
</script>
<template>
  <div class="gl-border-b gl-flex gl-justify-between gl-bg-subtle">
    <div><!-- TODO: Add blame legend (https://gitlab.com/gitlab-org/gitlab/-/issues/554948)--></div>
    <blame-preferences :has-revs-file="hasRevsFile" />
  </div>
</template>

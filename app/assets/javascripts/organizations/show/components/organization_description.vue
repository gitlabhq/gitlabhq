<script>
import SafeHtml from '~/vue_shared/directives/safe_html';

export default {
  name: 'OrganizationDescription',
  directives: {
    SafeHtml,
  },
  props: {
    organization: {
      type: Object,
      required: true,
    },
  },
};
</script>

<template>
  <div
    v-if="organization.description_html"
    v-safe-html="organization.description_html"
    class="md gl-mt-5"
  ></div>
</template>

<script>
import PageHeading from '~/vue_shared/components/page_heading.vue';

export default {
  components: { PageHeading },
};
</script>

<template>
  <page-heading :heading="s__('AccessTokens|Generate fine-grained token')">
    <template #description>
      {{
        s__(
          'AccessTokens|Fine-grained personal access tokens give you granular control over the specific resources and actions available to the token.',
        )
      }}
    </template>
  </page-heading>
</template>

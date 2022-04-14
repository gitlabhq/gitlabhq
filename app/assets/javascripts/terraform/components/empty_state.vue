<script>
import { GlEmptyState, GlLink } from '@gitlab/ui';
import { s__ } from '~/locale';
import { helpPagePath } from '~/helpers/help_page_helper';

export default {
  i18n: {
    title: s__("Terraform|Your project doesn't have any Terraform state files"),
    description: s__('Terraform|How to use GitLab-managed Terraform state?'),
  },
  docsUrl: helpPagePath('user/infrastructure/iac/terraform_state'),
  components: {
    GlEmptyState,
    GlLink,
  },
  props: {
    image: {
      type: String,
      required: true,
    },
  },
};
</script>

<template>
  <gl-empty-state :svg-path="image" :title="$options.i18n.title">
    <template #description>
      <gl-link :href="$options.docsUrl">{{ $options.i18n.description }}</gl-link>
    </template>
  </gl-empty-state>
</template>

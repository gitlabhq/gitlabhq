<script>
import { GlEmptyState, GlIcon, GlLink } from '@gitlab/ui';
import { helpPagePath } from '~/helpers/help_page_helper';

export default {
  components: {
    GlEmptyState,
    GlIcon,
    GlLink,
  },
  props: {
    image: {
      type: String,
      required: true,
    },
  },
  computed: {
    docsUrl() {
      return helpPagePath('user/infrastructure/terraform_state');
    },
  },
};
</script>

<template>
  <gl-empty-state :svg-path="image" :title="s__('Terraform|Get started with Terraform')">
    <template #description>
      <p>
        <gl-link :href="docsUrl" target="_blank"
          >{{ s__('Terraform|How to use GitLab-managed Terraform State?') }}
          <gl-icon name="external-link"
        /></gl-link>
      </p>
    </template>
  </gl-empty-state>
</template>

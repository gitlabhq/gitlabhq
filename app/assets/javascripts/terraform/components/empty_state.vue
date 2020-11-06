<script>
import { GlEmptyState, GlIcon, GlLink, GlSprintf } from '@gitlab/ui';

export default {
  components: {
    GlEmptyState,
    GlIcon,
    GlLink,
    GlSprintf,
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
  <gl-empty-state :svg-path="image" :title="s__('Terraform|Get started with Terraform')">
    <template #description>
      <p>
        <gl-sprintf
          :message="
            s__(
              'Terraform|Find out how to use the %{linkStart}GitLab managed Terraform State%{linkEnd}',
            )
          "
        >
          <template #link="{ content }">
            <gl-link
              href="https://docs.gitlab.com/ee/user/infrastructure/index.html"
              target="_blank"
            >
              {{ content }}
              <gl-icon name="external-link" />
            </gl-link>
          </template>
        </gl-sprintf>
      </p>
    </template>
  </gl-empty-state>
</template>

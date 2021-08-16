<script>
import { GlBanner } from '@gitlab/ui';
import { helpPagePath } from '~/helpers/help_page_helper';
import { setCookie } from '~/lib/utils/common_utils';
import { s__ } from '~/locale';

export default {
  name: 'TerraformNotification',
  i18n: {
    title: s__('TerraformBanner|Using Terraform? Try the GitLab Managed Terraform State'),
    description: s__(
      'TerraformBanner|The GitLab managed Terraform state backend can store your Terraform state easily and securely, and spares you from setting up additional remote resources. Its features include: versioning, encryption of the state file both in transit and at rest, locking, and remote Terraform plan/apply execution.',
    ),
    buttonText: s__("TerraformBanner|Learn more about GitLab's Backend State"),
  },
  components: {
    GlBanner,
  },
  inject: ['terraformImagePath', 'bannerDismissedKey'],
  data() {
    return {
      isVisible: true,
    };
  },
  computed: {
    docsUrl() {
      return helpPagePath('user/infrastructure/terraform_state');
    },
  },
  methods: {
    handleClose() {
      setCookie(this.bannerDismissedKey, true);
      this.isVisible = false;
    },
  },
};
</script>
<template>
  <div v-if="isVisible" class="gl-py-5">
    <gl-banner
      :title="$options.i18n.title"
      :button-text="$options.i18n.buttonText"
      :button-link="docsUrl"
      :svg-path="terraformImagePath"
      variant="promotion"
      @close="handleClose"
    >
      <p>{{ $options.i18n.description }}</p>
    </gl-banner>
  </div>
</template>

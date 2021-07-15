<script>
import { GlBanner } from '@gitlab/ui';
import { helpPagePath } from '~/helpers/help_page_helper';
import { parseBoolean, setCookie, getCookie } from '~/lib/utils/common_utils';
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
  props: {
    projectId: {
      type: Number,
      required: true,
    },
  },
  data() {
    return {
      isVisible: true,
    };
  },
  computed: {
    bannerDissmisedKey() {
      return `terraform_notification_dismissed_for_project_${this.projectId}`;
    },
    docsUrl() {
      return helpPagePath('user/infrastructure/terraform_state');
    },
  },
  created() {
    if (parseBoolean(getCookie(this.bannerDissmisedKey))) {
      this.isVisible = false;
    }
  },
  methods: {
    handleClose() {
      setCookie(this.bannerDissmisedKey, true);
      this.isVisible = false;
    },
  },
};
</script>
<template>
  <div v-if="isVisible">
    <div class="gl-py-5">
      <gl-banner
        :title="$options.i18n.title"
        :button-text="$options.i18n.buttonText"
        :button-link="docsUrl"
        variant="introduction"
        @close="handleClose"
      >
        <p>{{ $options.i18n.description }}</p>
      </gl-banner>
    </div>
  </div>
</template>

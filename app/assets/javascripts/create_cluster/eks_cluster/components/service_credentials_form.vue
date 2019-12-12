<script>
import { GlFormInput } from '@gitlab/ui';
import _ from 'underscore';
import { mapState, mapActions } from 'vuex';
import { sprintf, s__, __ } from '~/locale';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';
import LoadingButton from '~/vue_shared/components/loading_button.vue';

export default {
  components: {
    GlFormInput,
    LoadingButton,
    ClipboardButton,
  },
  props: {
    accountAndExternalIdsHelpPath: {
      type: String,
      required: true,
    },
    createRoleArnHelpPath: {
      type: String,
      required: true,
    },
    externalLinkIcon: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      roleArn: this.$store.state.roleArn,
    };
  },
  computed: {
    ...mapState(['accountId', 'externalId', 'isCreatingRole', 'createRoleError']),
    submitButtonDisabled() {
      return this.isCreatingRole || !this.roleArn;
    },
    submitButtonLabel() {
      return this.isCreatingRole
        ? __('Authenticating')
        : s__('ClusterIntegration|Authenticate with AWS');
    },
    accountAndExternalIdsHelpText() {
      const escapedUrl = _.escape(this.accountAndExternalIdsHelpPath);

      return sprintf(
        s__(
          'ClusterIntegration|Create a provision role on %{startAwsLink}Amazon Web Services %{externalLinkIcon}%{endLink} using the account and external ID above. %{startMoreInfoLink}More information%{endLink}',
        ),
        {
          startAwsLink:
            '<a href="https://console.aws.amazon.com/iam/home?#roles" target="_blank" rel="noopener noreferrer">',
          startMoreInfoLink: `<a href="${escapedUrl}" target="_blank" rel="noopener noreferrer">`,
          externalLinkIcon: this.externalLinkIcon,
          endLink: '</a>',
        },
        false,
      );
    },
    provisionRoleArnHelpText() {
      const escapedUrl = _.escape(this.createRoleArnHelpPath);

      return sprintf(
        s__(
          'ClusterIntegration|The Amazon Resource Name (ARN) associated with your role. If you do not have a provision role, first create one on  %{startAwsLink}Amazon Web Services %{externalLinkIcon}%{endLink} using the above account and external IDs. %{startMoreInfoLink}More information%{endLink}',
        ),
        {
          startAwsLink:
            '<a href="https://console.aws.amazon.com/iam/home?#roles" target="_blank" rel="noopener noreferrer">',
          startMoreInfoLink: `<a href="${escapedUrl}" target="_blank" rel="noopener noreferrer">`,
          externalLinkIcon: this.externalLinkIcon,
          endLink: '</a>',
        },
        false,
      );
    },
  },
  methods: {
    ...mapActions(['createRole']),
  },
};
</script>
<template>
  <form name="service-credentials-form" @submit.prevent="createRole({ roleArn, externalId })">
    <h2>{{ s__('ClusterIntegration|Authenticate with Amazon Web Services') }}</h2>
    <p>
      {{
        s__(
          'ClusterIntegration|You must grant access to your organization’s AWS resources in order to create a new EKS cluster. To grant access, create a provision role using the account and external ID below and provide us the ARN.',
        )
      }}
    </p>
    <div v-if="createRoleError" class="js-invalid-credentials bs-callout bs-callout-danger">
      {{ createRoleError }}
    </div>
    <div class="form-row">
      <div class="form-group col-md-6">
        <label for="gitlab-account-id">{{ __('Account ID') }}</label>
        <div class="input-group">
          <gl-form-input id="gitlab-account-id" type="text" readonly :value="accountId" />
          <div class="input-group-append">
            <clipboard-button
              :text="accountId"
              :title="__('Copy Account ID to clipboard')"
              class="input-group-text js-copy-account-id-button"
            />
          </div>
        </div>
      </div>
      <div class="form-group col-md-6">
        <label for="eks-external-id">{{ __('External ID') }}</label>
        <div class="input-group">
          <gl-form-input id="eks-external-id" type="text" readonly :value="externalId" />
          <div class="input-group-append">
            <clipboard-button
              :text="externalId"
              :title="__('Copy External ID to clipboard')"
              class="input-group-text js-copy-external-id-button"
            />
          </div>
        </div>
      </div>
      <div class="col-12 mb-3 mt-n3">
        <p class="form-text text-muted" v-html="accountAndExternalIdsHelpText"></p>
      </div>
    </div>
    <div class="form-group">
      <label for="eks-provision-role-arn">{{ s__('ClusterIntegration|Provision Role ARN') }}</label>
      <gl-form-input id="eks-provision-role-arn" v-model="roleArn" />
      <p class="form-text text-muted" v-html="provisionRoleArnHelpText"></p>
    </div>
    <loading-button
      class="js-submit-service-credentials btn-success"
      type="submit"
      :disabled="submitButtonDisabled"
      :loading="isCreatingRole"
      :label="submitButtonLabel"
    />
  </form>
</template>

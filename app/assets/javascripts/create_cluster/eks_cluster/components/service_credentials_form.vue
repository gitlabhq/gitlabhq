<script>
/* eslint-disable vue/no-v-html */
import { GlButton, GlFormGroup, GlFormInput, GlIcon, GlLink, GlSprintf, GlAlert } from '@gitlab/ui';
import { escape } from 'lodash';
import { mapState, mapActions } from 'vuex';
import { sprintf, s__, __ } from '~/locale';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';
import { DEFAULT_REGION } from '../constants';

export default {
  components: {
    GlButton,
    GlFormGroup,
    GlFormInput,
    GlIcon,
    GlLink,
    GlSprintf,
    ClipboardButton,
    GlAlert,
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
  i18n: {
    regionInputLabel: s__('ClusterIntegration|Cluster Region'),
    regionHelpPath: 'https://aws.amazon.com/about-aws/global-infrastructure/regions_az/',
    regionHelpText: s__(
      'ClusterIntegration|Select the region you want to create the new cluster in. Make sure you have access to this region for your role to be able to authenticate. If no region is selected, we will use %{codeStart}DEFAULT_REGION%{codeEnd}. Learn more about %{linkStart}Regions%{linkEnd}.',
    ),
    regionHelpTextDefaultRegion: DEFAULT_REGION,
  },
  data() {
    return {
      roleArn: this.$store.state.roleArn,
      selectedRegion: this.$store.state.selectedRegion,
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
      const escapedUrl = escape(this.accountAndExternalIdsHelpPath);

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
      const escapedUrl = escape(this.createRoleArnHelpPath);

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
  <form name="service-credentials-form">
    <h4>{{ s__('ClusterIntegration|Authenticate with Amazon Web Services') }}</h4>
    <p>
      {{
        s__(
          'ClusterIntegration|You must grant access to your organization’s AWS resources in order to create a new EKS cluster. To grant access, create a provision role using the account and external ID below and provide us the ARN.',
        )
      }}
    </p>
    <gl-alert
      v-if="createRoleError"
      class="js-invalid-credentials gl-mb-5"
      variant="danger"
      :dismissible="false"
    >
      {{ createRoleError }}
    </gl-alert>
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

    <gl-form-group :label="$options.i18n.regionInputLabel">
      <gl-form-input id="eks-region" v-model="selectedRegion" type="text" />

      <template #description>
        <gl-sprintf :message="$options.i18n.regionHelpText">
          <template #code>
            <code>{{ $options.i18n.regionHelpTextDefaultRegion }}</code>
          </template>

          <template #link="{ content }">
            <gl-link :href="$options.i18n.regionHelpPath" target="_blank">
              {{ content }}
              <gl-icon name="external-link" />
            </gl-link>
          </template>
        </gl-sprintf>
      </template>
    </gl-form-group>

    <gl-button
      variant="success"
      category="primary"
      type="submit"
      :disabled="submitButtonDisabled"
      :loading="isCreatingRole"
      @click.prevent="createRole({ roleArn, selectedRegion, externalId })"
    >
      {{ submitButtonLabel }}
    </gl-button>
  </form>
</template>

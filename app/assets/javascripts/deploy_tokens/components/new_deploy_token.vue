<script>
import {
  GlFormGroup,
  GlFormInput,
  GlFormCheckbox,
  GlButton,
  GlDatepicker,
  GlFormInputGroup,
  GlSprintf,
  GlLink,
} from '@gitlab/ui';
import { createAlert, VARIANT_INFO } from '~/flash';
import axios from '~/lib/utils/axios_utils';
import { formatDate } from '~/lib/utils/datetime_utility';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';
import { s__ } from '~/locale';

function defaultData() {
  return {
    expiresAt: null,
    name: '',
    newTokenDetails: null,
    readRepository: false,
    writeRepository: false,
    readRegistry: false,
    writeRegistry: false,
    readPackageRegistry: false,
    writePackageRegistry: false,
    username: '',
    placeholders: {
      link: { link: ['link_start', 'link_end'] },
      i: { i: ['i_start', 'i_end'] },
      code: { code: ['code_start', 'code_end'] },
    },
  };
}

export default {
  components: {
    GlFormGroup,
    GlFormInput,
    GlDatepicker,
    GlFormCheckbox,
    GlButton,
    GlFormInputGroup,
    ClipboardButton,
    GlSprintf,
    GlLink,
  },

  props: {
    createNewTokenPath: {
      type: String,
      required: true,
    },
    deployTokensHelpUrl: {
      type: String,
      required: true,
    },
    containerRegistryEnabled: {
      type: Boolean,
      required: true,
    },
    packagesRegistryEnabled: {
      type: Boolean,
      required: true,
    },
    tokenType: {
      type: String,
      required: true,
    },
  },

  data() {
    return defaultData();
  },
  translations: {
    addTokenButton: s__('DeployTokens|Create deploy token'),
    addTokenExpiryLabel: s__('DeployTokens|Expiration date (optional)'),
    addTokenExpiryDescription: s__(
      'DeployTokens|Enter an expiration date for your token. Defaults to never expire.',
    ),
    addTokenHeader: s__('DeployTokens|New deploy token'),
    addTokenDescription: s__(
      'DeployTokens|Create a new deploy token for all projects in this group. %{link_start}What are deploy tokens?%{link_end}',
    ),
    addTokenNameLabel: s__('DeployTokens|Name'),
    addTokenNameDescription: s__('DeployTokens|Enter a unique name for your deploy token.'),
    addTokenScopesLabel: s__('DeployTokens|Scopes (select at least one)'),
    addTokenUsernameDescription: s__(
      'DeployTokens|Enter a username for your token. Defaults to %{code_start}gitlab+deploy-token-{n}%{code_end}.',
    ),
    addTokenUsernameLabel: s__('DeployTokens|Username (optional)'),
    newTokenCopyMessage: s__('DeployTokens|Copy deploy token'),
    newProjectTokenCreated: s__('DeployTokens|Your new project deploy token has been created.'),
    newGroupTokenCreated: s__('DeployTokens|Your new group deploy token has been created.'),
    newTokenDescription: s__(
      'DeployTokens|Use this token as a password. Save it. This password can %{i_start}not%{i_end} be recovered.',
    ),
    newTokenMessage: s__('DeployTokens|Your New Deploy Token'),
    newTokenUsernameCopy: s__('DeployTokens|Copy username'),
    newTokenUsernameDescription: s__(
      'DeployTokens|This username supports access. %{link_start}What kind of access?%{link_end}',
    ),
    readRepositoryHelp: s__('DeployTokens|Allows read-only access to the repository.'),
    readRegistryHelp: s__('DeployTokens|Allows read-only access to registry images.'),
    writeRegistryHelp: s__('DeployTokens|Allows read and write access to registry images.'),
    readPackageRegistryHelp: s__('DeployTokens|Allows read-only access to the package registry.'),
    writePackageRegistryHelp: s__(
      'DeployTokens|Allows read and write access to the package registry.',
    ),
    createTokenFailedAlert: s__('DeployTokens|Failed to create a new deployment token'),
  },
  computed: {
    formattedExpiryDate() {
      return this.expiresAt ? formatDate(this.expiresAt, 'yyyy-mm-dd') : '';
    },
    newTokenCreatedMessage() {
      return this.tokenType === 'group'
        ? this.$options.translations.newGroupTokenCreated
        : this.$options.translations.newProjectTokenCreated;
    },
  },
  methods: {
    createDeployToken() {
      return axios
        .post(this.createNewTokenPath, {
          deploy_token: {
            expires_at: this.expiresAt,
            name: this.name,
            read_repository: this.readRepository,
            read_registry: this.readRegistry,
            write_registry: this.writeRegistry,
            read_package_registry: this.readPackageRegistry,
            write_package_registry: this.writePackageRegistry,
            username: this.username,
          },
        })
        .then((response) => {
          this.newTokenDetails = response.data;
          this.resetData();
          createAlert({
            variant: VARIANT_INFO,
            message: this.newTokenCreatedMessage,
          });
        })
        .catch((error) => {
          createAlert({
            message:
              error?.response?.data?.message || this.$options.translations.createTokenFailedAlert,
          });
        });
    },
    resetData() {
      const newData = defaultData();
      delete newData.newTokenDetails;
      Object.keys(newData).forEach((k) => {
        this[k] = newData[k];
      });
    },
  },
};
</script>
<template>
  <div>
    <div v-if="newTokenDetails" class="created-deploy-token-container info-well">
      <div class="well-segment">
        <h5>{{ $options.translations.newTokenMessage }}</h5>
        <gl-form-group>
          <template #description>
            <div class="deploy-token-help-block gl-mt-2 text-success">
              <gl-sprintf
                :message="$options.translations.newTokenUsernameDescription"
                :placeholders="placeholders.link"
              >
                <template #link="{ content }">
                  <gl-link :href="deployTokensHelpUrl" target="_blank">{{ content }}</gl-link>
                </template>
              </gl-sprintf>
            </div>
          </template>
          <gl-form-input-group
            name="deploy-token-user"
            :value="newTokenDetails.username"
            select-on-click
            readonly
          >
            <template #append>
              <clipboard-button
                :text="newTokenDetails.username"
                :title="$options.translations.newTokenUsernameCopy"
              />
            </template>
          </gl-form-input-group>
        </gl-form-group>
        <gl-form-group>
          <template #description>
            <div class="deploy-token-help-block gl-mt-2 text-danger">
              <gl-sprintf
                :message="$options.translations.newTokenDescription"
                :placeholders="placeholders.i"
              >
                <template #i="{ content }">
                  <i>{{ content }}</i>
                </template>
              </gl-sprintf>
            </div>
          </template>
          <gl-form-input-group :value="newTokenDetails.token" name="deploy-token" readonly>
            <template #append>
              <clipboard-button
                :text="newTokenDetails.token"
                :title="$options.translations.newTokenCopyMessage"
              />
            </template>
          </gl-form-input-group>
        </gl-form-group>
      </div>
    </div>
    <h5>{{ $options.translations.addTokenHeader }}</h5>
    <p class="profile-settings-content">
      <gl-sprintf
        :message="$options.translations.addTokenDescription"
        :placeholders="placeholders.link"
      >
        <template #link="{ content }">
          <gl-link :href="deployTokensHelpUrl" target="_blank">{{ content }}</gl-link>
        </template>
      </gl-sprintf>
    </p>
    <gl-form-group
      :label="$options.translations.addTokenNameLabel"
      :description="$options.translations.addTokenNameDescription"
      label-for="deploy_token_name"
    >
      <gl-form-input id="deploy_token_name" v-model="name" name="deploy_token_name" />
    </gl-form-group>
    <gl-form-group
      :label="$options.translations.addTokenExpiryLabel"
      :description="$options.translations.addTokenExpiryDescription"
      label-for="deploy_token_expires_at"
    >
      <gl-form-input
        id="deploy_token_expires_at"
        name="deploy_token_expires_at"
        :value="formattedExpiryDate"
        data-qa-selector="deploy_token_expires_at_field"
      />
    </gl-form-group>
    <gl-form-group
      :label="$options.translations.addTokenUsernameLabel"
      label-for="deploy_token_username"
    >
      <template #description>
        <gl-sprintf
          :message="$options.translations.addTokenUsernameDescription"
          :placeholders="placeholders.code"
        >
          <template #code="{ content }">
            <code>{{ content }}</code>
          </template>
        </gl-sprintf>
      </template>
      <gl-form-input id="deploy_token_username" v-model="username" />
    </gl-form-group>
    <gl-form-group
      :label="$options.translations.addTokenScopesLabel"
      label-for="deploy-token-scopes"
    >
      <div id="deploy-token-scopes">
        <!-- eslint-disable @gitlab/vue-require-i18n-strings -->
        <gl-form-checkbox
          id="deploy_token_read_repository"
          v-model="readRepository"
          name="deploy_token_read_repository"
          data-qa-selector="deploy_token_read_repository_checkbox"
        >
          read_repository
          <template #help>{{ $options.translations.readRepositoryHelp }}</template>
        </gl-form-checkbox>
        <gl-form-checkbox
          v-if="containerRegistryEnabled"
          id="deploy_token_read_registry"
          v-model="readRegistry"
          name="deploy_token_read_registry"
          data-qa-selector="deploy_token_read_registry_checkbox"
        >
          read_registry
          <template #help>{{ $options.translations.readRegistryHelp }}</template>
        </gl-form-checkbox>
        <gl-form-checkbox
          v-if="containerRegistryEnabled"
          id="deploy_token_write_registry"
          v-model="writeRegistry"
          name="deploy_token_write_registry"
          data-qa-selector="deploy_token_write_registry_checkbox"
        >
          write_registry
          <template #help>{{ $options.translations.writeRegistryHelp }}</template>
        </gl-form-checkbox>
        <gl-form-checkbox
          v-if="packagesRegistryEnabled"
          id="deploy_token_read_package_registry"
          v-model="readPackageRegistry"
          name="deploy_token_read_package_registry"
          data-qa-selector="deploy_token_read_package_registry_checkbox"
        >
          read_package_registry
          <template #help>{{ $options.translations.readPackageRegistryHelp }}</template>
        </gl-form-checkbox>
        <gl-form-checkbox
          v-if="packagesRegistryEnabled"
          id="deploy_token_write_package_registry"
          v-model="writePackageRegistry"
          name="deploy_token_write_package_registry"
          data-qa-selector="deploy_token_write_package_registry_checkbox"
        >
          write_package_registry
          <template #help>{{ $options.translations.writePackageRegistryHelp }}</template>
        </gl-form-checkbox>
        <!-- eslint-enable @gitlab/vue-require-i18n-strings -->
      </div>
    </gl-form-group>
    <div>
      <gl-button variant="success" @click="createDeployToken">
        {{ $options.translations.addTokenButton }}
      </gl-button>
    </div>
    <gl-datepicker v-model="expiresAt" target="#deploy_token_expires_at" container="body" />
  </div>
</template>

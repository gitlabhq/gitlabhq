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
  GlAlert,
} from '@gitlab/ui';
import { MountingPortal } from 'portal-vue';
import { createAlert, VARIANT_INFO } from '~/alert';
import axios from '~/lib/utils/axios_utils';
import { formatDate } from '~/lib/utils/datetime_utility';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';
import translations from '../deploy_token_translations';

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
    GlAlert,
    MountingPortal,
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
    return this.defaultData();
  },
  translations,
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
    getWritePackageRegistryHelpText() {
      return this.tokenType === 'group'
        ? this.$options.translations.groupWritePackageRegistryHelp
        : this.$options.translations.projectWritePackageRegistryHelp;
    },
    defaultData() {
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
        scopes: [
          {
            id: 'deploy_token_read_repository',
            isShown: true,
            value: false,
            helpText: this.$options.translations.readRepositoryHelp,
            scopeName: 'read_repository',
          },
          {
            id: 'deploy_token_read_registry',
            isShown: this.$props.containerRegistryEnabled,
            value: false,
            helpText: this.$options.translations.readRegistryHelp,
            scopeName: 'read_registry',
          },
          {
            id: 'deploy_token_write_registry',
            isShown: this.$props.containerRegistryEnabled,
            value: false,
            helpText: this.$options.translations.writeRegistryHelp,
            scopeName: 'write_registry',
          },
          {
            id: 'deploy_token_read_package_registry',
            isShown: this.$props.packagesRegistryEnabled,
            value: false,
            helpText: this.$options.translations.readPackageRegistryHelp,
            scopeName: 'read_package_registry',
          },
          {
            id: 'deploy_token_write_package_registry',
            isShown: this.$props.packagesRegistryEnabled,
            value: false,
            helpText: this.getWritePackageRegistryHelpText(),
            scopeName: 'write_package_registry',
          },
        ],
        username: '',
        placeholders: {
          link: { link: ['link_start', 'link_end'] },
          i: { i: ['i_start', 'i_end'] },
          code: { code: ['code_start', 'code_end'] },
        },
      };
    },
    createDeployToken() {
      const scopes = {};
      this.scopes.forEach((scope) => {
        scopes[scope.scopeName] = scope.value;
      });
      const body = {
        deploy_token: {
          expires_at: this.expiresAt,
          name: this.name,
          username: this.username,
          ...scopes,
        },
      };

      return axios
        .post(this.createNewTokenPath, body)
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
      const newData = this.defaultData();
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
    <mounting-portal append mount-to="#new-deploy-token-alert">
      <gl-alert
        v-if="newTokenDetails"
        variant="success"
        class="gl-mb-4"
        @dismiss="newTokenDetails = null"
      >
        <h5 class="!gl-mt-0">{{ $options.translations.newTokenMessage }}</h5>
        <gl-form-group>
          <template #description>
            <div class="gl-mt-2">
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
        <gl-form-group class="gl-mb-0">
          <template #description>
            <div class="gl-mt-2">
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
      </gl-alert>
    </mounting-portal>
    <h4 class="gl-mt-0">{{ $options.translations.addTokenHeader }}</h4>
    <p>
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
      <gl-form-input
        id="deploy_token_name"
        v-model="name"
        class="gl-form-input-xl"
        name="deploy_token_name"
      />
    </gl-form-group>
    <gl-form-group
      :label="$options.translations.addTokenExpiryLabel"
      :description="$options.translations.addTokenExpiryDescription"
      label-for="deploy_token_expires_at"
    >
      <gl-form-input
        id="deploy_token_expires_at"
        class="gl-form-input-xl"
        name="deploy_token_expires_at"
        :value="formattedExpiryDate"
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
      <gl-form-input id="deploy_token_username" v-model="username" width="xl" />
    </gl-form-group>
    <gl-form-group
      :label="$options.translations.addTokenScopesLabel"
      label-for="deploy-token-scopes"
    >
      <div id="deploy-token-scopes">
        <!-- eslint-disable @gitlab/vue-require-i18n-strings -->
        <template v-for="scope in scopes">
          <gl-form-checkbox
            v-if="scope.isShown"
            :id="scope.id"
            :key="scope.id"
            v-model="scope.value"
            :name="scope.id"
          >
            {{ scope.scopeName }}
            <template #help>{{ scope.helpText }}</template>
          </gl-form-checkbox>
        </template>
        <!-- eslint-enable @gitlab/vue-require-i18n-strings -->
      </div>
    </gl-form-group>
    <div>
      <gl-button variant="confirm" @click="createDeployToken">
        {{ $options.translations.addTokenButton }}
      </gl-button>
      <gl-button class="js-toggle-button gl-ml-3">
        {{ $options.translations.cancelTokenCreation }}
      </gl-button>
    </div>
    <gl-datepicker v-model="expiresAt" target="#deploy_token_expires_at" container="body" />
  </div>
</template>

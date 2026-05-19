<script>
import {
  GlForm,
  GlFormGroup,
  GlFormInput,
  GlFormTextarea,
  GlButton,
  GlExperimentBadge,
  GlTabs,
  GlLink,
  GlSprintf,
  GlLoadingIcon,
} from '@gitlab/ui';
import { union } from 'lodash-es';
import PageHeading from '~/vue_shared/components/page_heading.vue';
import { scrollTo, scrollToElement } from '~/lib/utils/scroll_utils';
import { helpPagePath } from '~/helpers/help_page_helper';
import { getParameterByName } from '~/lib/utils/url_utility';
import { s__, __, sprintf } from '~/locale';
import { createAlert } from '~/alert';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import { TYPENAME_USER, TYPENAME_PERSONAL_ACCESS_TOKEN } from '~/graphql_shared/constants';
import createGranularPersonalAccessTokenMutation from '~/personal_access_tokens/graphql/create_granular_personal_access_token.mutation.graphql';
import getSourcePersonalAccessToken from '~/personal_access_tokens/graphql/get_source_personal_access_token.query.graphql';
import {
  ACCESS_SELECTED_MEMBERSHIPS_ENUM,
  MAX_NAME_LENGTH,
  MAX_DESCRIPTION_LENGTH,
  ACCESS_USER_ENUM,
  ACCESS_NAMESPACE_ENUMS,
  NAMESPACE_ACCESS_TYPES,
} from '~/personal_access_tokens/constants';
import ConfirmUnsavedChangesDialog from '~/vue_shared/components/confirm_unsaved_changes_dialog.vue';
import { defaultDate } from '~/vue_shared/access_tokens/utils';
import CreatedPersonalAccessToken from '../created_personal_access_token.vue';
import PersonalAccessTokenExpirationDate from './personal_access_token_expiration_date.vue';
import PersonalAccessTokenScopeSelector from './personal_access_token_scope_selector.vue';
import PersonalAccessTokenNamespaceSelector from './personal_access_token_namespace_selector.vue';
import PersonalAccessTokenPermissionsSelector from './personal_access_token_permissions_selector.vue';

export default {
  name: 'CreateGranularPersonalAccessTokenForm',
  components: {
    PageHeading,
    GlForm,
    GlFormGroup,
    GlFormInput,
    GlFormTextarea,
    PersonalAccessTokenExpirationDate,
    PersonalAccessTokenScopeSelector,
    PersonalAccessTokenNamespaceSelector,
    PersonalAccessTokenPermissionsSelector,
    GlButton,
    ConfirmUnsavedChangesDialog,
    CreatedPersonalAccessToken,
    GlExperimentBadge,
    GlTabs,
    GlLink,
    GlSprintf,
    GlLoadingIcon,
    AskDapPermissions: () =>
      import(
        'ee_component/personal_access_tokens/components/create_granular_token/ask_dap_permissions.vue'
      ),
  },
  mixins: [glFeatureFlagsMixin()],
  inject: ['accessTokenMaxDate', 'accessTokenTableUrl'],
  data() {
    return {
      sourceTokenId: getParameterByName('source_token_id'),
      // form is the source of truth for all token data
      // the data is passed down to all child components using v-model
      form: {
        name: '',
        description: '',
        expirationDate: defaultDate(this.accessTokenMaxDate),
        access: null,
        namespaces: [],
        permissions: {
          namespace: [],
          user: [],
        },
      },
      errors: {
        name: '',
        description: '',
        expirationDate: '',
        access: '',
        namespaces: '',
        permissions: '',
      },
      aiPermissions: {
        suggested: [],
        removed: [],
      },
      isFormDirty: false,
      isSubmitting: false,
      createdToken: null,
    };
  },
  apollo: {
    // eslint-disable-next-line @gitlab/vue-no-undef-apollo-properties
    sourceToken: {
      query: getSourcePersonalAccessToken,
      manual: true,
      variables() {
        return {
          userId: convertToGraphQLId(TYPENAME_USER, gon.current_user_id),
          id: convertToGraphQLId(TYPENAME_PERSONAL_ACCESS_TOKEN, this.sourceTokenId),
        };
      },
      skip() {
        return !this.sourceTokenId;
      },
      result({ data }) {
        if (!data) return;
        const token = data.user.personalAccessTokens.nodes[0];

        if (token?.granular) {
          this.duplicateToken(token);
        }
      },
      error(error) {
        createAlert({
          message: this.$options.i18n.sourceTokenFetchError,
          captureError: true,
          error,
        });
      },
    },
  },
  computed: {
    hasErrors() {
      return Object.values(this.errors).some((error) => error !== '');
    },
    renderNamespaceSelector() {
      return this.form.access === ACCESS_SELECTED_MEMBERSHIPS_ENUM;
    },
    targetBoundaries() {
      return {
        namespace: ACCESS_NAMESPACE_ENUMS,
        user: [ACCESS_USER_ENUM],
      };
    },
    granularScopes() {
      const scopes = [];

      if (this.form.permissions.namespace.length) {
        scopes.push({
          access: this.form.access,
          resourceIds: this.form.namespaces.map((namespace) => namespace.id),
          permissions: this.form.permissions.namespace,
        });
      }

      if (this.form.permissions.user.length) {
        scopes.push({
          access: ACCESS_USER_ENUM,
          permissions: this.form.permissions.user,
        });
      }

      return scopes;
    },
  },
  watch: {
    form: {
      deep: true,
      handler() {
        this.isFormDirty = true;
      },
    },
  },
  methods: {
    handlePermissionsSelected(permissionNames) {
      this.aiPermissions.suggested = [...permissionNames];
    },
    handlePermissionsCleared(permissionNames) {
      this.aiPermissions.removed = [...permissionNames];
    },
    duplicateToken(token) {
      let access = '';
      const namespaces = [];

      let namespacePermissions = [];
      let userPermissions = [];

      for (const scope of token.scopes) {
        const scopePermissions = scope.permissions.map((p) => p.name);

        if (NAMESPACE_ACCESS_TYPES.includes(scope.access)) {
          access = scope.access;
          namespaces.push(scope.project || scope.namespace);
          namespacePermissions = union(namespacePermissions, scopePermissions);
        } else if (scope.access === ACCESS_USER_ENUM) {
          userPermissions = union(userPermissions, scopePermissions);
        }
      }

      this.form = {
        name: sprintf(this.$options.i18n.duplicateTokenName, { name: token.name }),
        description: token.description || '',
        expirationDate: defaultDate(this.accessTokenMaxDate),
        access,
        namespaces: namespaces.filter(Boolean),
        permissions: {
          namespace: namespacePermissions,
          user: userPermissions,
        },
      };
    },
    validateForm() {
      // reset the validation
      this.errors = {
        name: '',
        description: '',
        expirationDate: '',
        access: '',
        namespaces: '',
        permissions: '',
      };

      if (!this.form.name) {
        this.errors.name = this.$options.i18n.nameError;
      }

      if (!this.form.description) {
        this.errors.description = this.$options.i18n.descriptionError;
      }

      if (this.accessTokenMaxDate && !this.form.expirationDate) {
        this.errors.expirationDate = this.$options.i18n.expirationDateError;
      }

      if (this.form.permissions.namespace.length && !this.form.access) {
        this.errors.access = this.$options.i18n.scopeError;
      }

      if (this.renderNamespaceSelector && !this.form.namespaces.length) {
        this.errors.namespaces = this.$options.i18n.namespaceError;
      }

      if (!this.form.permissions.namespace.length && !this.form.permissions.user.length) {
        this.errors.permissions = this.$options.i18n.permissionsError;
      }

      return this.hasErrors;
    },
    async createGranularToken() {
      if (this.validateForm()) {
        this.$nextTick(() => {
          const firstError = this.$el.querySelector('.invalid-feedback');
          if (firstError) {
            scrollToElement(firstError, { behavior: 'smooth', offset: -100 });
          }
        });

        return;
      }

      try {
        this.isSubmitting = true;

        const response = await this.$apollo.mutate({
          mutation: createGranularPersonalAccessTokenMutation,
          variables: {
            input: {
              name: this.form.name,
              description: this.form.description,
              expiresAt: this.form.expirationDate,
              granularScopes: this.granularScopes,
            },
          },
        });

        const { errors, token } = response.data.personalAccessTokenCreate;

        if (errors[0]) {
          this.showCreateError(new Error(), errors[0]);
        } else {
          this.createdToken = token;
          this.isFormDirty = false;
        }
      } catch (error) {
        this.showCreateError(error, this.$options.i18n.createError);
      } finally {
        this.isSubmitting = false;
      }
    },
    showCreateError(error, message) {
      scrollTo({ top: 0, behavior: 'smooth' }, this.$el);
      createAlert({ message, error, captureError: true });
    },
  },
  i18n: {
    heading: s__('AccessTokens|Generate fine-grained token'),
    description: s__(
      'AccessTokens|Fine-grained personal access tokens give you granular control over the specific resources and actions available to the token.',
    ),
    basicInformation: s__('AcccessTokens|Basic Information'),
    nameLabel: s__('AccessTokens|Name'),
    nameError: s__('AccessTokens|Add token name.'),
    descriptionLabel: s__('AccessTokens|Description'),
    descriptionError: s__('AccessTokens|Add token description.'),
    expirationDateError: s__('AccessTokens|Add token expiration date.'),
    scopeError: s__('AccessTokens|Set group and project access.'),
    namespaceError: s__('AccessTokens|At least one group or project is required.'),
    permissionsError: s__('AccessTokens|Add at least one resource with permissions.'),
    duplicateTokenName: s__('AccessTokens|%{name} (copy)'),
    sourceTokenFetchError: s__(
      'AccessTokens|Failed to load source token. Please fill in the form manually.',
    ),
    cancelButton: __('Cancel'),
    createButton: s__('AccessTokens|Generate token'),
    createError: s__('AccessTokens|Token generation unsuccessful. Please try again.'),
    addPermissions: s__('AccessTokens|Add resource permissions'),
    addPermissionsDescription: s__(
      'AccessTokens|Add only the %{linkStart}minimum resource and permissions %{linkEnd} needed for your token. Permissions not included in your assigned role have no effect.',
    ),
    publicAccessNote: s__(
      'AccessTokens|Publicly visible resources are accessible without a permission. See the %{linkStart}list of publicly accessible endpoints%{linkEnd}.',
    ),
  },
  fineGrainedTokensDocPath: helpPagePath('auth/tokens/fine_grained_access_tokens.md'),
  publiclyAccessibleEndpointsDocPath: helpPagePath('auth/tokens/fine_grained_access_tokens.md', {
    anchor: 'publicly-accessible-endpoints',
  }),
  MAX_NAME_LENGTH,
  MAX_DESCRIPTION_LENGTH,
};
</script>

<template>
  <div>
    <confirm-unsaved-changes-dialog :has-unsaved-changes="isFormDirty" />
    <created-personal-access-token
      v-if="createdToken"
      :token="createdToken"
      :href="accessTokenTableUrl"
    />

    <div v-else>
      <page-heading>
        <template #heading>
          <span class="gl-flex">
            {{ $options.i18n.heading }}
            <gl-experiment-badge type="beta" class="gl-self-center" />
          </span>
        </template>
        <template #description>
          {{ $options.i18n.description }}
        </template>
      </page-heading>

      <gl-loading-icon v-if="$apollo.queries.sourceToken.loading" size="lg" />

      <gl-form v-else class="js-quick-submit">
        <section class="gl-w-full lg:gl-w-1/2">
          <h2 class="gl-heading-3">{{ $options.i18n.basicInformation }}</h2>
          <gl-form-group
            :label="$options.i18n.nameLabel"
            label-for="token-name"
            :invalid-feedback="errors.name"
            :state="!errors.name"
          >
            <gl-form-input
              id="token-name"
              v-model.trim="form.name"
              :state="!errors.name"
              :maxlength="$options.MAX_NAME_LENGTH"
            />
          </gl-form-group>

          <gl-form-group
            :label="$options.i18n.descriptionLabel"
            label-for="token-description"
            :invalid-feedback="errors.description"
            :state="!errors.description"
          >
            <gl-form-textarea
              id="token-description"
              v-model.trim="form.description"
              :state="!errors.description"
              :maxlength="$options.MAX_DESCRIPTION_LENGTH"
            />
          </gl-form-group>

          <personal-access-token-expiration-date
            v-model="form.expirationDate"
            :error="errors.expirationDate"
          />
        </section>
        <section class="gl-mt-8">
          <personal-access-token-scope-selector v-model="form.access" :error="errors.access">
            <template #namespace-selector>
              <personal-access-token-namespace-selector
                v-if="renderNamespaceSelector"
                v-model="form.namespaces"
                :error="errors.namespaces"
                class="gl-mt-4 gl-w-full lg:gl-w-1/2"
              />
            </template>
          </personal-access-token-scope-selector>
        </section>
        <section class="gl-mt-8">
          <h2 class="gl-heading-3 gl-mb-2">{{ $options.i18n.addPermissions }}</h2>
          <p class="gl-text-subtle">
            <gl-sprintf :message="$options.i18n.addPermissionsDescription">
              <template #link="{ content }">
                <gl-link :href="$options.fineGrainedTokensDocPath" target="_blank">
                  {{ content }}
                </gl-link>
              </template>
            </gl-sprintf>
            <gl-sprintf :message="$options.i18n.publicAccessNote">
              <template #link="{ content }">
                <gl-link :href="$options.publiclyAccessibleEndpointsDocPath" target="_blank">
                  {{ content }}
                </gl-link>
              </template>
            </gl-sprintf>
          </p>
          <gl-tabs content-class="!gl-p-0">
            <template #tabs-end>
              <ask-dap-permissions
                v-if="$options.components.AskDapPermissions && glFeatures.patPermissionsSuggestions"
                @permissions-selected="handlePermissionsSelected"
                @permissions-cleared="handlePermissionsCleared"
              />
            </template>
            <personal-access-token-permissions-selector
              v-model="form.permissions.namespace"
              :error="errors.permissions"
              :target-boundaries="targetBoundaries.namespace"
              :ai-permissions="aiPermissions"
            />

            <personal-access-token-permissions-selector
              v-model="form.permissions.user"
              :error="errors.permissions"
              :target-boundaries="targetBoundaries.user"
              :ai-permissions="aiPermissions"
            />
          </gl-tabs>
        </section>

        <div class="settings-sticky-footer gl-flex gl-flex-wrap gl-gap-3">
          <gl-button variant="confirm" :loading="isSubmitting" @click="createGranularToken">
            {{ $options.i18n.createButton }}
          </gl-button>

          <gl-button :href="accessTokenTableUrl">
            {{ $options.i18n.cancelButton }}
          </gl-button>
        </div>
      </gl-form>
    </div>
  </div>
</template>

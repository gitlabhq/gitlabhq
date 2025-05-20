<script>
import {
  GlButton,
  GlDatepicker,
  GlForm,
  GlFormCheckboxGroup,
  GlFormCheckbox,
  GlFormFields,
  GlFormTextarea,
  GlLink,
  GlSprintf,
} from '@gitlab/ui';
import { formValidators } from '@gitlab/ui/dist/utils';
import { mapActions, mapState } from 'pinia';
import { helpPagePath } from '~/helpers/help_page_helper';
import { toISODateFormat } from '~/lib/utils/datetime_utility';
import { __, s__ } from '~/locale';

import { useAccessTokens } from '../stores/access_tokens';
import { defaultDate } from '../utils';

export default {
  components: {
    GlButton,
    GlDatepicker,
    GlForm,
    GlFormCheckboxGroup,
    GlFormCheckbox,
    GlFormFields,
    GlFormTextarea,
    GlLink,
    GlSprintf,
    MaxExpirationDateMessage: () =>
      import('ee_component/vue_shared/components/access_tokens/max_expiration_date_message.vue'),
  },
  inject: ['accessTokenMaxDate', 'accessTokenMinDate'],
  data() {
    const maxDate = this.accessTokenMaxDate ? new Date(this.accessTokenMaxDate) : null;
    if (maxDate) {
      this.$options.fields.expiresAt.validators.push(
        formValidators.required(s__('AccessTokens|Expiration date is required.')),
      );
    }
    const minDate = new Date(this.accessTokenMinDate);
    const expiresAt = defaultDate(maxDate);
    return { maxDate, minDate, values: { expiresAt } };
  },
  computed: {
    ...mapState(useAccessTokens, ['busy']),
  },
  methods: {
    ...mapActions(useAccessTokens, ['createToken', 'setShowCreateForm']),
    clearDatepicker() {
      this.values.expiresAt = null;
    },
    reset() {
      this.setShowCreateForm(false);
    },
    submit() {
      const expiresAt = this.values.expiresAt ? toISODateFormat(this.values.expiresAt) : null;
      this.createToken({ ...this.values, expiresAt });
    },
  },
  helpScopes: helpPagePath('user/profile/personal_access_tokens', {
    anchor: 'personal-access-token-scopes',
  }),
  scopes: [
    {
      value: 'read_service_ping',
      text: s__(
        'AccessTokens|Grant access to download Service Ping payload via API when authenticated as an admin user.',
      ),
    },
    {
      value: 'read_user',
      text: s__(
        'AccessTokens|Grants read-only access to your profile through the /user API endpoint, which includes username, public email, and full name. Also grants access to read-only API endpoints under /users.',
      ),
    },
    {
      value: 'read_repository',
      text: s__(
        'AccessTokens|Grants read-only access to repositories on private projects using Git-over-HTTP or the Repository Files API.',
      ),
    },
    {
      value: 'read_api',
      text: s__(
        'AccessTokens|Grants read access to the API, including all groups and projects, the container registry, and the package registry.',
      ),
    },
    {
      value: 'self_rotate',
      text: s__('AccessTokens|Grants permission for token to rotate itself.'),
    },
    {
      value: 'write_repository',
      text: s__(
        'AccessTokens|Grants read-write access to repositories on private projects using Git-over-HTTP (not using the API).',
      ),
    },
    {
      value: 'api',
      text: s__(
        'AccessTokens|Grants complete read/write access to the API, including all groups and projects, the container registry, the dependency proxy, and the package registry.',
      ),
    },
    {
      value: 'ai_features',
      text: s__('AccessTokens|Grants access to GitLab Duo related API endpoints.'),
    },
    { value: 'create_runner', text: s__('AccessTokens|Grants create access to the runners.') },
    { value: 'manage_runner', text: s__('AccessTokens|Grants access to manage the runners.') },
    {
      value: 'k8s_proxy',
      text: s__(
        'AccessTokens|Grants permission to perform Kubernetes API calls using the agent for Kubernetes.',
      ),
    },
    {
      value: 'sudo',
      text: s__(
        'AccessTokens|Grants permission to perform API actions as any user in the system, when authenticated as an admin user.',
      ),
    },
    {
      value: 'admin_mode',
      text: s__(
        'AccessTokens|Grants permission to perform API actions as an administrator, when Admin Mode is enabled.',
      ),
    },
  ],
  fields: {
    name: {
      label: s__('AccessTokens|Token name'),
      validators: [formValidators.required(s__('AccessTokens|Token name is required.'))],
      groupAttrs: {
        class: 'gl-form-input-xl',
      },
    },
    description: {
      label: s__('AccessTokens|Description'),
      groupAttrs: {
        optional: true,
        'optional-text': __('(optional)'),
      },
    },
    expiresAt: {
      label: s__('AccessTokens|Expiration date'),
      validators: [],
    },
    scopes: {
      label: s__('AccessTokens|Select scopes'),
      validators: [
        (value) => (value?.length ? '' : s__('AccessTokens|At least one scope is required.')),
      ],
    },
  },
};
</script>

<template>
  <gl-form
    id="token-create-form"
    class="gl-rounded-base gl-bg-subtle gl-p-5"
    @submit.prevent
    @reset="reset"
  >
    <gl-form-fields
      v-model="values"
      form-id="token-create-form"
      :fields="$options.fields"
      @submit="submit"
    >
      <template #input(description)="{ id, input, value }">
        <gl-form-textarea :id="id" :value="value" @input="input" />
      </template>

      <template #group(expiresAt)-description>
        <max-expiration-date-message :max-date="maxDate" />
      </template>

      <template #input(expiresAt)="{ id, input, validation, value }">
        <gl-datepicker
          show-clear-button
          :max-date="maxDate"
          :min-date="minDate"
          :input-id="id"
          :state="validation.state"
          :value="value"
          :target="null"
          @input="input"
          @clear="clearDatepicker"
        />
      </template>

      <template #group(scopes)-label-description>
        <gl-sprintf
          :message="
            s__(
              'AccessTokens|Scopes set the permission levels granted to the token. %{linkStart}Learn more%{linkEnd}.',
            )
          "
        >
          <template #link="{ content }">
            <gl-link :href="$options.helpScopes" target="_blank">{{ content }}</gl-link>
          </template>
        </gl-sprintf>
      </template>

      <template #input(scopes)="{ id, input, validation, value }">
        <gl-form-checkbox-group :id="id" :state="validation.state" :checked="value" @input="input">
          <gl-form-checkbox
            v-for="scope in $options.scopes"
            :key="scope.value"
            :value="scope.value"
            :state="validation.state"
          >
            {{ scope.value }}
            <template #help>{{ scope.text }}</template>
          </gl-form-checkbox>
        </gl-form-checkbox-group>
      </template>
    </gl-form-fields>

    <div class="gl-flex gl-gap-3">
      <gl-button variant="confirm" type="submit" class="js-no-auto-disable" :loading="busy">
        {{ s__('AccessTokens|Create token') }}
      </gl-button>
      <gl-button variant="default" type="reset">
        {{ __('Cancel') }}
      </gl-button>
    </div>
  </gl-form>
</template>

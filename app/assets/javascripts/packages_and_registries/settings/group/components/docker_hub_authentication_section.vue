<script>
import { GlAlert, GlButton, GlCard, GlForm, GlFormInput, GlFormGroup } from '@gitlab/ui';
import updateDockerHubCredentialsMutation from '~/packages_and_registries/settings/group/graphql/mutations/update_docker_hub_credentials.mutation.graphql';

const SECRET_PLACEHOLDER = '*****';

export default {
  components: {
    GlAlert,
    GlButton,
    GlCard,
    GlForm,
    GlFormGroup,
    GlFormInput,
  },
  inject: ['groupPath'],
  props: {
    formData: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      updateInProgress: false,
      errorMessage: null,
      identity: this.formData?.identity ?? null,
      secret: null,
      secretPlaceholder: this.formData?.identity ? SECRET_PLACEHOLDER : '',
    };
  },
  computed: {
    mutationVariables() {
      return {
        input: {
          groupPath: this.groupPath,
          identity: this.identity,
          secret: this.secret,
        },
      };
    },
  },
  methods: {
    dismissAlert() {
      this.errorMessage = null;
    },
    async handleSubmit() {
      try {
        this.updateInProgress = true;
        this.dismissAlert();
        const { data } = await this.$apollo.mutate({
          mutation: updateDockerHubCredentialsMutation,
          variables: this.mutationVariables,
        });

        const [errorMessage] = data.updateDependencyProxySettings?.errors ?? [];
        if (errorMessage) {
          this.errorMessage = errorMessage;
          return;
        }

        this.secret = null;
        this.secretPlaceholder = SECRET_PLACEHOLDER;
        this.$emit('success');
      } catch (e) {
        this.errorMessage = e.message;
      } finally {
        this.updateInProgress = false;
      }
    },
  },
};
</script>

<template>
  <gl-card>
    <template #header>
      <h3 class="gl-m-0 gl-text-base gl-font-bold">
        {{ s__('DependencyProxy|Docker Hub authentication') }}
      </h3>
    </template>
    <template #default>
      <p data-testid="description">
        {{
          s__(
            'DependencyProxy|Credentials used to authenticate with Docker Hub when pulling images.',
          )
        }}
      </p>
      <gl-alert v-if="errorMessage" variant="warning" class="gl-mb-5" @dismiss="dismissAlert">
        {{ errorMessage }}
      </gl-alert>
      <gl-form @submit.prevent="handleSubmit">
        <div class="gl-flex gl-flex-col gl-gap-5 md:gl-flex-row md:gl-justify-between">
          <gl-form-group
            class="gl-grow gl-basis-0"
            :label="s__('DependencyProxy|Identity')"
            label-for="identity"
            :description="
              s__(
                'DependencyProxy|Enter your username (for password or personal access token) or organization name (for organization access token).',
              )
            "
          >
            <gl-form-input id="identity" v-model.trim="identity" required trim width="xl" />
          </gl-form-group>
          <gl-form-group
            class="gl-grow gl-basis-0"
            :label="s__('DependencyProxy|Secret')"
            label-for="secret"
            :description="
              s__(
                'DependencyProxy|Enter your password, personal access token, or organization access token.',
              )
            "
          >
            <gl-form-input
              id="secret"
              v-model.trim="secret"
              required
              trim
              width="xl"
              :placeholder="secretPlaceholder"
            />
          </gl-form-group>
        </div>
        <gl-button
          type="submit"
          category="primary"
          variant="confirm"
          :loading="updateInProgress"
          class="js-no-auto-disable"
        >
          {{ __('Save changes') }}
        </gl-button>
      </gl-form>
    </template>
  </gl-card>
</template>

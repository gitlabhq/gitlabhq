<script>
import { GlButton, GlFormGroup, GlFormInput, GlFormInputGroup } from '@gitlab/ui';
import axios from '~/lib/utils/axios_utils';
import { s__, sprintf } from '~/locale';

import MultiStepFormTemplate from '~/vue_shared/components/multi_step_form_template.vue';

export default {
  components: {
    GlButton,
    GlFormGroup,
    GlFormInput,
    GlFormInputGroup,
    MultiStepFormTemplate,
  },
  inject: ['importByUrlValidatePath'],
  data() {
    return {
      repositoryUrl: '',
      repositoryUsername: '',
      repositoryPassword: '',
      isCheckingConnection: false,
    };
  },
  methods: {
    async checkConnection() {
      this.isCheckingConnection = true;
      try {
        const { data } = await axios.post(this.importByUrlValidatePath, {
          url: this.repositoryUrl,
          user: this.repositoryUsername,
          password: this.repositoryPassword,
        });

        if (data.success) {
          this.$toast.show(s__('Integrations|Connection successful.'));
        } else {
          this.$toast.show(
            sprintf(s__('ProjectImport|Connection failed: %{error}'), { error: data.message }),
          );
        }
      } catch (error) {
        this.$toast.show(sprintf(s__('ProjectImport|Connection failed: %{error}'), { error }));
      } finally {
        this.isCheckingConnection = false;
      }
    },
  },
  repositoryUrlPlaceholder: 'https://gitlab.company.com/group/project.git',
};
</script>

<template>
  <multi-step-form-template
    :title="s__('ProjectImport|Import repository by URL')"
    :current-step="3"
  >
    <template #form>
      <gl-form-group
        :label="__('Git repository URL')"
        label-for="repository-url"
        :label-description="
          s__('ProjectImport|The repository must be accessible over http://, https:// or git://')
        "
      >
        <gl-form-input-group>
          <gl-form-input
            id="repository-url"
            v-model="repositoryUrl"
            data-testid="repository-url"
            :placeholder="$options.repositoryUrlPlaceholder"
          />
          <template #append>
            <gl-button
              :loading="isCheckingConnection"
              data-testid="check-connection"
              @click="checkConnection"
            >
              {{ s__('ProjectImport|Check connection') }}
            </gl-button>
          </template>
        </gl-form-input-group>
      </gl-form-group>

      <div class="gl-grid gl-grid-cols-2 gl-gap-5">
        <gl-form-group :label="__('Username (optional)')" label-for="repository-username">
          <gl-form-input
            id="repository-username"
            v-model="repositoryUsername"
            data-testid="repository-username"
            autocomplete="off"
          />
        </gl-form-group>

        <gl-form-group :label="__('Password (optional)')" label-for="repository-password">
          <gl-form-input
            id="repository-password"
            v-model="repositoryPassword"
            data-testid="repository-password"
            type="password"
            autocomplete="off"
          />
        </gl-form-group>
      </div>
    </template>

    <template #next>
      <gl-button
        category="primary"
        variant="confirm"
        :disabled="true"
        data-testid="import-project-by-url-next-button"
      >
        {{ __('Next step') }}
      </gl-button>
    </template>
    <template #back>
      <gl-button
        category="primary"
        variant="default"
        data-testid="import-project-by-url-back-button"
        @click="$emit('back')"
      >
        {{ __('Go back') }}
      </gl-button>
    </template>
  </multi-step-form-template>
</template>

<script>
import {
  GlForm,
  GlFormGroup,
  GlFormInput,
  GlFormTextarea,
  GlAlert,
  GlButton,
  GlLink,
  GlSprintf,
} from '@gitlab/ui';
import TitleArea from '~/vue_shared/components/registry/title_area.vue';
import { visitUrl } from '~/lib/utils/url_utility';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import { helpPagePath } from '~/helpers/help_page_helper';
import createModelMutation from '../graphql/mutations/create_model.mutation.graphql';
import {
  NEW_MODEL_LABEL,
  ERROR_CREATING_MODEL_LABEL,
  CREATE_MODEL_WITH_CLIENT_LABEL,
  NAME_LABEL,
  DESCRIPTION_LABEL,
  CREATE_MODEL_LABEL,
} from '../translations';

export default {
  name: 'NewMlModel',
  components: {
    TitleArea,
    GlForm,
    GlFormInput,
    GlFormGroup,
    GlFormTextarea,
    GlAlert,
    GlButton,
    GlLink,
    GlSprintf,
  },
  props: {
    projectPath: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      errorMessage: '',
      modelName: '',
      modelDescription: '',
    };
  },
  methods: {
    async createModel() {
      this.errorMessage = '';
      try {
        const variables = {
          projectPath: this.projectPath,
          name: this.modelName,
          description: this.modelDescription,
        };

        const { data } = await this.$apollo.mutate({
          mutation: createModelMutation,
          variables,
        });

        const [error] = data?.mlModelCreate?.errors || [];

        if (error) {
          this.errorMessage = data.mlModelCreate.errors.join(', ');
        } else {
          visitUrl(data?.mlModelCreate?.model?._links?.showPath);
        }
      } catch (error) {
        Sentry.captureException(error);
        this.errorMessage = ERROR_CREATING_MODEL_LABEL;
      }
    },
  },
  i18n: {
    NEW_MODEL_LABEL,
    CREATE_MODEL_WITH_CLIENT_LABEL,
    NAME_LABEL,
    DESCRIPTION_LABEL,
    CREATE_MODEL_LABEL,
  },
  docHref: helpPagePath('user/project/ml/model_registry/index.md'),
};
</script>

<template>
  <div>
    <title-area :title="$options.i18n.NEW_MODEL_LABEL" />

    <gl-alert variant="tip" icon="bulb" class="gl-mb-3" :dismissible="false">
      <gl-sprintf :message="$options.i18n.CREATE_MODEL_WITH_CLIENT_LABEL">
        <template #link="{ content }">
          <gl-link :href="$options.docHref" target="_blank">{{ content }}</gl-link>
        </template>
      </gl-sprintf>
    </gl-alert>

    <gl-alert
      v-if="errorMessage"
      :dismissible="false"
      variant="danger"
      class="gl-mb-3"
      data-testid="new-model-errors"
    >
      {{ errorMessage }}
    </gl-alert>

    <gl-form @submit.prevent="createModel">
      <gl-form-group :label="$options.i18n.NAME_LABEL">
        <gl-form-input v-model="modelName" />
      </gl-form-group>

      <gl-form-group :label="$options.i18n.DESCRIPTION_LABEL" optional>
        <gl-form-textarea v-model="modelDescription" />
      </gl-form-group>

      <gl-button type="submit" variant="confirm" class="js-no-auto-disable">{{
        $options.i18n.CREATE_MODEL_LABEL
      }}</gl-button>
    </gl-form>
  </div>
</template>

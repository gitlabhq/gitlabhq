<script>
import { GlForm, GlFormFields, GlButton } from '@gitlab/ui';
import { s__, __ } from '~/locale';
import SettingsBlock from '~/vue_shared/components/settings/settings_block.vue';
import VisibilityLevelRadioButtons from '~/visibility_level/components/visibility_level_radio_buttons.vue';
import FormErrorsAlert from '~/organizations/shared/components/errors_alert.vue';
import {
  ORGANIZATION_VISIBILITY_LEVEL_DESCRIPTIONS,
  VISIBILITY_LEVEL_PRIVATE_INTEGER,
  VISIBILITY_LEVEL_PUBLIC_INTEGER,
  VISIBILITY_LEVELS_INTEGER_TO_STRING,
} from '~/visibility_level/constants';
import { FORM_FIELD_VISIBILITY_LEVEL } from '~/organizations/shared/constants';
import { createAlert, VARIANT_INFO } from '~/alert';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import { TYPE_ORGANIZATION } from '~/graphql_shared/constants';
import { scrollUp } from '~/lib/utils/scroll_utils';
import organizationUpdateMutation from '../graphql/mutations/organization_update.mutation.graphql';

export default {
  name: 'VisibilityLevel',
  components: {
    GlForm,
    GlFormFields,
    GlButton,
    FormErrorsAlert,
    SettingsBlock,
    VisibilityLevelRadioButtons,
  },
  inject: ['organization', 'maxGroupVisibilityLevel'],
  formId: 'organization-visibility-form',
  fields: {
    [FORM_FIELD_VISIBILITY_LEVEL]: {
      label: __('Visibility level'),
    },
  },
  i18n: {
    settingsBlock: {
      title: __('Visibility'),
      description: s__('Organization|Choose organization visibility level.'),
    },
  },
  ORGANIZATION_VISIBILITY_LEVEL_DESCRIPTIONS,
  props: {
    id: {
      type: String,
      required: true,
    },
    expanded: {
      type: Boolean,
      required: true,
    },
  },
  emits: ['toggle-expand'],
  data() {
    return {
      formValues: {
        [FORM_FIELD_VISIBILITY_LEVEL]: this.organization.visibilityLevel,
      },
      loading: false,
      errors: [],
    };
  },
  computed: {
    availableVisibilityLevels() {
      return [VISIBILITY_LEVEL_PRIVATE_INTEGER, VISIBILITY_LEVEL_PUBLIC_INTEGER];
    },
  },
  methods: {
    async onSubmit() {
      this.errors = [];
      this.loading = true;

      try {
        const {
          data: {
            organizationUpdate: { errors },
          },
        } = await this.$apollo.mutate({
          mutation: organizationUpdateMutation,
          variables: {
            input: {
              id: convertToGraphQLId(TYPE_ORGANIZATION, this.organization.id),
              visibility:
                VISIBILITY_LEVELS_INTEGER_TO_STRING[this.formValues[FORM_FIELD_VISIBILITY_LEVEL]],
            },
          },
        });

        if (errors.length) {
          this.errors = errors;

          return;
        }

        createAlert({
          message: s__('Organization|Organization visibility successfully updated.'),
          variant: VARIANT_INFO,
        });
        scrollUp();
      } catch (error) {
        createAlert({
          message: s__(
            'Organization|An error occurred updating your organization. Please try again.',
          ),
          error,
          captureError: true,
        });
        scrollUp();
      } finally {
        this.loading = false;
      }
    },
  },
};
</script>

<template>
  <settings-block
    :id="id"
    :expanded="expanded"
    :title="$options.i18n.settingsBlock.title"
    @toggle-expand="$emit('toggle-expand', $event)"
  >
    <template #description>{{ $options.i18n.settingsBlock.description }}</template>
    <template #default>
      <form-errors-alert v-model="errors" :scroll-on-error="true" />
      <gl-form :id="$options.formId">
        <gl-form-fields
          v-model="formValues"
          :form-id="$options.formId"
          :fields="$options.fields"
          @submit="onSubmit"
        >
          <template #input(visibilityLevel)="{ value, input }">
            <!-- maxGroupVisibilityLevel is the highest visibility level (integer) among the top-level groups (TLGs) in this organization. -->
            <!-- We pass it as the minVisibilityLevel prop because we want visibility levels under this integer to be disabled -->
            <!-- For example, if an organization has a public (20) TLG the minimum visibility level is 20 so the organization cannot be private (0) -->
            <!-- If the organization has a private (0) TLG the minimum visibility level is 0 so the organization can be private (0) or public (20) -->
            <visibility-level-radio-buttons
              :checked="value"
              :visibility-levels="availableVisibilityLevels"
              :visibility-level-descriptions="$options.ORGANIZATION_VISIBILITY_LEVEL_DESCRIPTIONS"
              :min-visibility-level="maxGroupVisibilityLevel"
              @input="input"
            >
              <template #disabled-message>
                <p>
                  {{
                    s__(
                      'Organization|Visibility levels that are more restrictive than the groups in this Organization have been disabled.',
                    )
                  }}
                </p>
              </template>
            </visibility-level-radio-buttons>
          </template>
        </gl-form-fields>
        <gl-button
          type="submit"
          variant="confirm"
          class="js-no-auto-disable"
          :loading="loading"
          data-testid="submit-button"
          >{{ __('Save changes') }}</gl-button
        >
      </gl-form>
    </template>
  </settings-block>
</template>

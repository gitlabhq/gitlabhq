<script>
import { GlForm, GlFormFields } from '@gitlab/ui';
import { s__, __ } from '~/locale';
import SettingsBlock from '~/vue_shared/components/settings/settings_block.vue';
import VisibilityLevelRadioButtons from '~/visibility_level/components/visibility_level_radio_buttons.vue';
import { ORGANIZATION_VISIBILITY_LEVEL_DESCRIPTIONS } from '~/visibility_level/constants';
import { FORM_FIELD_VISIBILITY_LEVEL } from '~/organizations/shared/constants';
import HelpPageLink from '~/vue_shared/components/help_page_link/help_page_link.vue';

export default {
  name: 'VisibilityLevel',
  components: {
    GlForm,
    GlFormFields,
    HelpPageLink,
    SettingsBlock,
    VisibilityLevelRadioButtons,
  },
  inject: ['organization'],
  formId: 'organization-visibility-form',
  fields: {
    [FORM_FIELD_VISIBILITY_LEVEL]: {
      label: __('Visibility level'),
      labelDescription: s__('Organization|Who can see this organization?'),
    },
  },
  i18n: {
    settingsBlock: {
      title: __('Visibility'),
      description: s__('Organization|Choose organization visibility level.'),
    },
    learnMore: s__('Organization|Learn more about visibility levels'),
  },
  ORGANIZATION_VISIBILITY_LEVEL_DESCRIPTIONS,
  data() {
    return {
      formValues: {
        [FORM_FIELD_VISIBILITY_LEVEL]: this.organization.visibilityLevel,
      },
    };
  },
  computed: {
    availableVisibilityLevels() {
      return [this.organization.visibilityLevel];
    },
  },
};
</script>

<template>
  <settings-block id="organization-settings-visibility" :title="$options.i18n.settingsBlock.title">
    <template #description>{{ $options.i18n.settingsBlock.description }}</template>
    <template #default>
      <gl-form :id="$options.formId">
        <gl-form-fields v-model="formValues" :form-id="$options.formId" :fields="$options.fields">
          <template #group(visibilityLevel)-label-description>
            {{ $options.fields.visibilityLevel.labelDescription }}
            <help-page-link
              href="user/organization/_index"
              anchor="view-an-organizations-visibility-level"
              >{{ $options.i18n.learnMore }}</help-page-link
            >.
          </template>
          <template #input(visibilityLevel)="{ value, input }">
            <visibility-level-radio-buttons
              :checked="value"
              :visibility-levels="availableVisibilityLevels"
              :visibility-level-descriptions="$options.ORGANIZATION_VISIBILITY_LEVEL_DESCRIPTIONS"
              @input="input"
            />
          </template>
        </gl-form-fields>
      </gl-form>
    </template>
  </settings-block>
</template>

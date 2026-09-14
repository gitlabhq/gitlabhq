<script>
import { GlFormGroup, GlFormRadioGroup, GlFormRadio } from '@gitlab/ui';
import { ACCESS_LEVEL_DEFAULT, ACCESS_LEVEL_OWNER } from '~/organizations/shared/constants';
import { s__ } from '~/locale';

export default {
  name: 'OrganizationUserTypeField',
  radioOptions: [
    {
      text: s__('Organization|Organization regular user'),
      description: s__('Organization|Access to their groups and projects.'),
      value: ACCESS_LEVEL_DEFAULT,
    },
    {
      text: s__('Organization|Organization administrator'),
      description: s__(
        'Organization|Full access to all groups, projects, users, features, and the Organization admin area.',
      ),
      value: ACCESS_LEVEL_OWNER,
    },
  ],
  components: { GlFormGroup, GlFormRadioGroup, GlFormRadio },
  props: {
    initialAccessLevel: {
      type: String,
      required: false,
      default: ACCESS_LEVEL_DEFAULT,
    },
    inputName: {
      type: String,
      required: false,
      default: 'user[organization_access_level]',
    },
  },
  data() {
    return {
      accessLevel: this.initialAccessLevel,
    };
  },
};
</script>

<template>
  <gl-form-group
    :label="s__('Organization|Organization user type')"
    :label-description="
      s__(
        'Organization|Define user access to groups, projects, users, and features in this Organization.',
      )
    "
  >
    <gl-form-radio-group v-model="accessLevel" class="gl-mt-5" :name="inputName">
      <gl-form-radio
        v-for="radioOption in $options.radioOptions"
        :key="radioOption.value"
        :value="radioOption.value"
      >
        {{ radioOption.text }}
        <template #help>{{ radioOption.description }}</template>
      </gl-form-radio>
    </gl-form-radio-group>
  </gl-form-group>
</template>

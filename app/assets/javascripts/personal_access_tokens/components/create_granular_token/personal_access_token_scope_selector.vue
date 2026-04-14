<script>
import { GlFormGroup, GlFormRadioGroup, GlFormRadio } from '@gitlab/ui';
import { s__ } from '~/locale';
import {
  ACCESS_PERSONAL_PROJECTS_ENUM,
  ACCESS_SELECTED_MEMBERSHIPS_ENUM,
  ACCESS_ALL_MEMBERSHIPS_ENUM,
} from '~/personal_access_tokens/constants';

export default {
  name: 'PersonalAccessTokenScopeSelector',
  components: {
    GlFormGroup,
    GlFormRadioGroup,
    GlFormRadio,
  },
  props: {
    value: {
      type: String,
      required: false,
      default: null,
    },
    error: {
      type: String,
      required: false,
      default: '',
    },
  },
  emits: ['input'],
  computed: {
    selectedGroupAccessOption: {
      get() {
        return this.value;
      },
      set(val) {
        this.$emit('input', val);
      },
    },
    groupAccessOptions() {
      return [
        { text: this.$options.i18n.personalProjects, value: ACCESS_PERSONAL_PROJECTS_ENUM },
        { text: this.$options.i18n.allMemberships, value: ACCESS_ALL_MEMBERSHIPS_ENUM },
        {
          text: this.$options.i18n.selectedMemberships,
          value: ACCESS_SELECTED_MEMBERSHIPS_ENUM,
          helpText: this.$options.i18n.selectedMembershipsHelpText,
        },
      ];
    },
  },
  i18n: {
    groupAccess: s__('AccessTokens|Group and project access'),
    groupAccessDescription: s__(
      'AccessTokens|Required only if you add group and project resources.',
    ),
    personalProjects: s__('AccessTokens|Only my personal projects'),
    allMemberships: s__("AccessTokens|All groups and projects that I'm a member of"),
    selectedMemberships: s__("AccessTokens|Only specific groups or projects that I'm a member of"),
    selectedMembershipsHelpText: s__(
      'AccessTokens|Adding a group includes its subgroups and projects',
    ),
  },
};
</script>

<template>
  <div>
    <h2 class="gl-heading-3 gl-mb-2">{{ $options.i18n.groupAccess }}</h2>
    <div class="gl-mb-2 gl-text-subtle">{{ $options.i18n.groupAccessDescription }}</div>

    <div v-if="error" class="invalid-feedback gl-block">{{ error }}</div>

    <gl-form-group :state="!error" label-for="group-access" class="gl-mb-0 gl-mt-4">
      <gl-form-radio-group id="group-access" v-model="selectedGroupAccessOption">
        <gl-form-radio
          v-for="option in groupAccessOptions"
          :key="option.value"
          :value="option.value"
        >
          {{ option.text }}
          <template #help>
            {{ option.helpText }}
          </template>
        </gl-form-radio>
      </gl-form-radio-group>
    </gl-form-group>

    <slot name="namespace-selector"></slot>
  </div>
</template>

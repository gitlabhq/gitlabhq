<script>
import {
  GlFormGroup,
  GlFormRadioGroup,
  GlFormRadio,
  GlTabs,
  GlTab,
  GlLink,
  GlSprintf,
} from '@gitlab/ui';
import { helpPagePath } from '~/helpers/help_page_helper';
import { s__, __ } from '~/locale';
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
    GlTabs,
    GlTab,
    GlLink,
    GlSprintf,
  },
  props: {
    error: {
      type: String,
      required: false,
      default: '',
    },
  },
  emits: ['input'],
  data() {
    return {
      selectedGroupAccessOption: null,
    };
  },
  computed: {
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
    defineScopeLabel: s__('AccessTokens|Define scope'),
    scopesDescription: s__(
      'AccessTokens|Add only the %{linkStart}minimum resource and permissions %{linkEnd} needed for your token. Permissions that exceed your assigned role will have no effect.',
    ),
    groupTab: __('Group and project'),
    groupAccess: s__('AccessTokens|Group and project access'),
    personalProjects: s__('AccessTokens|Only personal projects'),
    allMemberships: s__("AccessTokens|All groups and projects that I'm a member of"),
    selectedMemberships: s__("AccessTokens|Only specific groups or projects that I'm a member of"),
    selectedMembershipsHelpText: s__(
      'AccessTokens|Adding a group includes its subgroups and projects',
    ),
    userTab: __('User'),
  },
  scopesHelpPagePath: helpPagePath('user/profile/personal_access_tokens', {
    anchor: 'personal-access-token-scopes',
  }),
};
</script>

<template>
  <div>
    <h2 class="gl-heading-2 gl-mt-7">{{ $options.i18n.defineScopeLabel }}</h2>
    <p class="gl-text-subtle">
      <gl-sprintf :message="$options.i18n.scopesDescription">
        <template #link="{ content }">
          <gl-link :href="$options.scopesHelpPagePath">{{ content }}</gl-link>
        </template>
      </gl-sprintf>
    </p>

    <gl-tabs>
      <gl-tab :title="$options.i18n.groupTab" class="gl-mt-4 gl-pb-0">
        <gl-form-group
          :label="$options.i18n.groupAccess"
          :invalid-feedback="error"
          :state="!error"
          label-for="group-access"
          class="gl-mb-0"
        >
          <gl-form-radio-group
            id="group-access"
            v-model="selectedGroupAccessOption"
            @input="$emit('input', $event)"
          >
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
        <slot name="namespace-permissions"></slot>
      </gl-tab>

      <gl-tab :title="$options.i18n.userTab">
        <slot name="user-permissions"></slot>
      </gl-tab>
    </gl-tabs>
  </div>
</template>

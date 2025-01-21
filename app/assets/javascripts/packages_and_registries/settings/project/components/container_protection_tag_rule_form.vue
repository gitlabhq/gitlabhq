<script>
import { GlFormGroup, GlForm, GlFormInput, GlFormSelect, GlLink, GlSprintf } from '@gitlab/ui';
import {
  MinimumAccessLevelOptions,
  GRAPHQL_ACCESS_LEVEL_VALUE_MAINTAINER,
} from '~/packages_and_registries/settings/project/constants';

export default {
  components: {
    GlForm,
    GlFormGroup,
    GlFormInput,
    GlFormSelect,
    GlLink,
    GlSprintf,
  },
  inject: ['projectPath'],
  data() {
    return {
      protectionRuleFormData: {
        tagNamePattern: '',
        minimumAccessLevelForPush: GRAPHQL_ACCESS_LEVEL_VALUE_MAINTAINER,
        minimumAccessLevelForDelete: GRAPHQL_ACCESS_LEVEL_VALUE_MAINTAINER,
      },
    };
  },
  minimumAccessLevelOptions: MinimumAccessLevelOptions,
};
</script>

<template>
  <gl-form>
    <gl-form-group
      :label="s__('ContainerRegistry|Protect container tags matching')"
      label-for="input-tag-name-pattern"
    >
      <gl-form-input
        id="input-tag-name-pattern"
        v-model.trim="protectionRuleFormData.tagNamePattern"
        type="text"
      />
      <template #description>
        <gl-sprintf
          :message="
            s__(
              'ContainerRegistry|Tags with names that match this regex pattern are protected. Must be less than 100 characters. %{linkStart}What regex patterns are supported?%{linkEnd}',
            )
          "
        >
          <template #link="{ content }">
            <gl-link href="https://github.com/google/re2/wiki/syntax" target="_blank">{{
              content
            }}</gl-link>
          </template>
        </gl-sprintf>
      </template>
    </gl-form-group>

    <gl-form-group
      :label="s__('ContainerRegistry|Minimum role allowed to push')"
      label-for="input-minimum-access-level-for-push"
    >
      <gl-form-select
        id="input-minimum-access-level-for-push"
        v-model="protectionRuleFormData.minimumAccessLevelForPush"
        :options="$options.minimumAccessLevelOptions"
      />
      <template #description>
        {{
          s__(
            'ContainerRegistry|Only users with at least this role can push tags with a name that matches the protection rule.',
          )
        }}
      </template>
    </gl-form-group>

    <gl-form-group
      :label="s__('ContainerRegistry|Minimum role allowed to delete')"
      label-for="input-minimum-access-level-for-delete"
    >
      <gl-form-select
        id="input-minimum-access-level-for-delete"
        v-model="protectionRuleFormData.minimumAccessLevelForDelete"
        :options="$options.minimumAccessLevelOptions"
      />
      <template #description>
        {{
          s__(
            'ContainerRegistry|Only users with at least this role can delete tags with a name that matches the protection rule.',
          )
        }}
      </template>
    </gl-form-group>
  </gl-form>
</template>

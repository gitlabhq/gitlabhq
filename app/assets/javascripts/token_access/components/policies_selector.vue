<script>
import {
  GlCollapsibleListbox,
  GlFormRadioGroup,
  GlFormRadio,
  GlFormGroup,
  GlSprintf,
  GlLink,
} from '@gitlab/ui';
import { s__ } from '~/locale';
import { helpPagePath } from '~/helpers/help_page_helper';
import {
  POLICIES_BY_RESOURCE,
  JOB_TOKEN_RESOURCES,
  JOB_TOKEN_POLICIES,
  POLICY_NONE,
} from '../constants';

export default {
  components: {
    GlCollapsibleListbox,
    GlFormRadioGroup,
    GlFormRadio,
    GlFormGroup,
    GlSprintf,
    GlLink,
  },
  props: {
    isDefaultPermissionsSelected: {
      type: Boolean,
      required: true,
    },
    jobTokenPolicies: {
      type: Array,
      required: true,
    },
    disabled: {
      type: Boolean,
      required: true,
    },
  },
  computed: {
    selected() {
      // Create an object where the key is the resource key and the value is the None option.
      const selected = Object.keys(JOB_TOKEN_RESOURCES).reduce((acc, resourceKey) => {
        acc[resourceKey] = POLICY_NONE.value;
        return acc;
      }, {});
      // Then use the values in jobTokenPolicies to set the selected options.
      this.jobTokenPolicies.forEach((policyValue) => {
        const policy = JOB_TOKEN_POLICIES[policyValue];
        selected[policy.resource.value] = policyValue;
      });

      return selected;
    },
  },
  methods: {
    emitPermissionTypeChange(value) {
      this.$emit('update:isDefaultPermissionsSelected', value);
    },
    emitPoliciesChange(value, item) {
      const policies = { ...this.selected, [item.resource.value]: value };
      // Remove any '' values from the None policy.
      this.$emit('update:jobTokenPolicies', Object.values(policies).filter(Boolean));
    },
  },
  i18n: {
    defaultPermissions: s__(
      'JobToken|Job token inherits permissions from user role and membership.',
    ),
    fineGrainedPermissions: s__(
      `JobToken|Job token permissions are limited to user's role and selected resource and scopes.`,
    ),
  },
  POLICIES_BY_RESOURCE,
  apiEndpointsHelpPath: helpPagePath('ci/jobs/fine_grained_permissions', {
    anchor: 'available-api-endpoints',
  }),
};
</script>

<template>
  <div>
    <label>{{ s__('CICD|Permission configuration') }}</label>
    <gl-form-radio-group
      :checked="isDefaultPermissionsSelected"
      :disabled="disabled"
      class="gl-mb-5"
      @change="emitPermissionTypeChange"
    >
      <gl-form-radio :value="true" data-testid="default-radio">
        {{ s__('JobToken|Default permissions') }}
        <template #help>{{ $options.i18n.defaultPermissions }}</template>
      </gl-form-radio>
      <gl-form-radio :value="false" data-testid="fine-grained-radio">
        {{ s__('JobToken|Fine-grained permissions') }}
        <template #help>{{ $options.i18n.fineGrainedPermissions }}</template>
      </gl-form-radio>
    </gl-form-radio-group>

    <gl-form-group
      v-if="!isDefaultPermissionsSelected"
      :label="s__('JobToken|Select resources and scope')"
    >
      <template #label-description>
        <gl-sprintf
          :message="s__('JobToken|Learn more about available %{linkStart}API endpoints%{linkEnd}.')"
        >
          <template #link="{ content }">
            <gl-link :href="$options.apiEndpointsHelpPath" target="_blank">{{ content }}</gl-link>
          </template>
        </gl-sprintf>
      </template>

      <ul
        class="gl-mb-0 gl-mt-3 gl-grid gl-grid-cols-[minmax(14rem,max-content),minmax(10rem,max-content)] gl-items-center gl-gap-5 gl-pl-0"
        data-testid="resources-dropdowns"
      >
        <li
          v-for="item in $options.POLICIES_BY_RESOURCE"
          :key="item.resource.text"
          class="gl-contents"
        >
          {{ item.resource.text }}
          <gl-collapsible-listbox
            :items="item.policies"
            :disabled="disabled"
            :selected="selected[item.resource.value]"
            block
            @select="emitPoliciesChange($event, item)"
          />
        </li>
      </ul>
    </gl-form-group>
  </div>
</template>

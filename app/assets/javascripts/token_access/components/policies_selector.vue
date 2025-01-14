<script>
import { GlCollapsibleListbox, GlFormRadioGroup, GlFormRadio, GlTableLite } from '@gitlab/ui';
import { s__, __ } from '~/locale';
import {
  POLICIES_BY_RESOURCE,
  JOB_TOKEN_RESOURCES,
  JOB_TOKEN_POLICIES,
  POLICY_NONE,
} from '../constants';

export const TABLE_FIELDS = [
  {
    key: 'resource.text',
    label: s__('JobToken|Resource'),
    class: '!gl-border-none !gl-py-3 !gl-pl-0 !gl-align-middle gl-w-28',
  },
  {
    key: 'policies',
    label: __('Permissions'),
    class: '!gl-border-none !gl-py-3',
  },
];

export default {
  components: { GlCollapsibleListbox, GlFormRadioGroup, GlFormRadio, GlTableLite },
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
      'JobToken|Use the standard permissions model based on user membership and roles.',
    ),
    fineGrainedPermissions: s__(
      'JobToken|Apply permissions that grant access to individual resources.',
    ),
  },
  TABLE_FIELDS,
  POLICIES_BY_RESOURCE,
};
</script>

<template>
  <div>
    <label>{{ __('Permissions') }}</label>
    <gl-form-radio-group
      :checked="isDefaultPermissionsSelected"
      :disabled="disabled"
      class="gl-mb-6"
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

    <gl-table-lite
      v-if="!isDefaultPermissionsSelected"
      :fields="$options.TABLE_FIELDS"
      :items="$options.POLICIES_BY_RESOURCE"
      fixed
    >
      <template #cell(policies)="{ item, value: policies }">
        <gl-collapsible-listbox
          :items="policies"
          :disabled="disabled"
          :selected="selected[item.resource.value]"
          block
          class="gl-w-20"
          @select="emitPoliciesChange($event, item)"
        />
      </template>
    </gl-table-lite>
  </div>
</template>

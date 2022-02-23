<script>
import { GlButton, GlFormGroup, GlFormSelect } from '@gitlab/ui';
import { __ } from '~/locale';

export default {
  components: { GlButton, GlFormGroup, GlFormSelect },
  props: {
    availableRegions: { required: true, type: Array },
    environments: { required: true, type: Array },
    cancelPath: { required: true, type: String },
  },
  i18n: {
    title: __('Configure region for environment'),
    gcpRegionLabel: __('Region'),
    gcpRegionDescription: __('List of suitable GCP locations'),
    environmentLabel: __('Environment'),
    environmentDescription: __('List of environments for this project'),
    submitLabel: __('Configure region'),
    cancelLabel: __('Cancel'),
  },
};
</script>

<template>
  <div>
    <header class="gl-my-5 gl-border-b-1 gl-border-b-gray-100 gl-border-b-solid">
      <h1 class="gl-font-size-h1">{{ $options.i18n.title }}</h1>
    </header>

    <gl-form-group
      label-for="environment"
      :label="$options.i18n.environmentLabel"
      :description="$options.i18n.environmentDescription"
    >
      <gl-form-select id="environment" name="environment" required>
        <option value="*">{{ __('All') }}</option>
        <option v-for="environment in environments" :key="environment.id" :value="environment.name">
          {{ environment.name }}
        </option>
      </gl-form-select>
    </gl-form-group>

    <gl-form-group
      label-for="gcp_region"
      :label="$options.i18n.gcpRegionLabel"
      :description="$options.i18n.gcpRegionDescription"
    >
      <gl-form-select id="gcp_region" name="gcp_region" required :list="availableRegions">
        <option v-for="(region, index) in availableRegions" :key="index" :value="region">
          {{ region }}
        </option>
      </gl-form-select>
    </gl-form-group>

    <div class="form-actions row">
      <gl-button type="submit" category="primary" variant="confirm">
        {{ $options.i18n.submitLabel }}
      </gl-button>
      <gl-button class="gl-ml-1" :href="cancelPath">{{ $options.i18n.cancelLabel }}</gl-button>
    </div>
  </div>
</template>

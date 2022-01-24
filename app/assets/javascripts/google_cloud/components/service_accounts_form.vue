<script>
import { GlButton, GlFormGroup, GlFormSelect, GlFormCheckbox } from '@gitlab/ui';
import { __ } from '~/locale';

export default {
  components: { GlButton, GlFormGroup, GlFormSelect, GlFormCheckbox },
  props: {
    gcpProjects: { required: true, type: Array },
    environments: { required: true, type: Array },
    cancelPath: { required: true, type: String },
  },
  i18n: {
    title: __('Create service account'),
    gcpProjectLabel: __('Google Cloud project'),
    gcpProjectDescription: __(
      'New service account is generated for the selected Google Cloud project',
    ),
    environmentLabel: __('Environment'),
    environmentDescription: __('Generated service account is linked to the selected environment'),
    submitLabel: __('Create service account'),
    cancelLabel: __('Cancel'),
    checkboxLabel: __(
      'I understand the responsibilities involved with managing service account keys',
    ),
  },
};
</script>

<template>
  <div>
    <header class="gl-my-5 gl-border-b-1 gl-border-b-gray-100 gl-border-b-solid">
      <h2 class="gl-font-size-h1">{{ $options.i18n.title }}</h2>
    </header>
    <gl-form-group
      label-for="gcp_project"
      :label="$options.i18n.gcpProjectLabel"
      :description="$options.i18n.gcpProjectDescription"
    >
      <gl-form-select id="gcp_project" name="gcp_project" required>
        <option
          v-for="gcpProject in gcpProjects"
          :key="gcpProject.project_id"
          :value="gcpProject.project_id"
        >
          {{ gcpProject.name }}
        </option>
      </gl-form-select>
    </gl-form-group>
    <gl-form-group
      label-for="environment"
      :label="$options.i18n.environmentLabel"
      :description="$options.i18n.environmentDescription"
    >
      <gl-form-select id="environment" name="environment" required>
        <option value="*">{{ __('All') }}</option>
        <option
          v-for="environment in environments"
          :key="environment.name"
          :value="environment.name"
        >
          {{ environment.name }}
        </option>
      </gl-form-select>
    </gl-form-group>
    <gl-form-group>
      <gl-form-checkbox name="confirmation" required>
        {{ $options.i18n.checkboxLabel }}
      </gl-form-checkbox>
    </gl-form-group>

    <div class="form-actions row">
      <gl-button type="submit" category="primary" variant="confirm">
        {{ $options.i18n.submitLabel }}
      </gl-button>
      <gl-button class="gl-ml-1" :href="cancelPath">{{ $options.i18n.cancelLabel }}</gl-button>
    </div>
  </div>
</template>

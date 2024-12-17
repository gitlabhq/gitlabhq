<!-- eslint-disable vue/multi-word-component-names -->
<script>
import { GlButton, GlFormCheckbox, GlFormGroup, GlFormSelect } from '@gitlab/ui';
import { s__ } from '~/locale';

export default {
  ALL_REFS: '*',
  components: { GlButton, GlFormGroup, GlFormSelect, GlFormCheckbox },
  props: {
    gcpProjects: { required: true, type: Array },
    refs: { required: true, type: Array },
    cancelPath: { required: true, type: String },
  },
  i18n: {
    title: s__('GoogleCloud|Create service account'),
    gcpProjectLabel: s__('GoogleCloud|Google Cloud project'),
    gcpProjectDescription: s__(
      'GoogleCloud|New service account is generated for the selected Google Cloud project',
    ),
    refsLabel: s__('GoogleCloud|Refs'),
    refsDescription: s__(
      'GoogleCloud|Generated service account is linked to the selected branch or tag',
    ),
    submitLabel: s__('GoogleCloud|Create service account'),
    cancelLabel: s__('GoogleCloud|Cancel'),
    checkboxLabel: s__(
      'GoogleCloud|I understand the responsibilities involved with managing service account keys',
    ),
  },
};
</script>

<template>
  <div>
    <header class="gl-my-5 gl-border-b-1 gl-border-b-default gl-border-b-solid">
      <h2 class="gl-text-size-h1">{{ $options.i18n.title }}</h2>
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
      label-for="ref"
      :label="$options.i18n.refsLabel"
      :description="$options.i18n.refsDescription"
    >
      <gl-form-select id="ref" name="ref" required>
        <option :value="$options.ALL_REFS">{{ __('All') }}</option>
        <option v-for="ref in refs" :key="ref" :value="ref">
          {{ ref }}
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

<script>
import { GlButton, GlFormCheckbox, GlFormGroup, GlFormSelect } from '@gitlab/ui';
import { s__ } from '~/locale';

const i18n = {
  gcpProjectLabel: s__('CloudSeed|Google Cloud project'),
  gcpProjectDescription: s__(
    'CloudSeed|Database instance is generated within the selected Google Cloud project',
  ),
  refsLabel: s__('CloudSeed|Refs'),
  refsDescription: s__(
    'CloudSeed|Generated database instance is linked to the selected branch or tag',
  ),
  databaseVersionLabel: s__('CloudSeed|Database version'),
  tierLabel: s__('CloudSeed|Machine type'),
  tierDescription: s__('CloudSeed|Determines memory and virtual cores available to your instance'),
  checkboxLabel: s__(
    'CloudSeed|I accept Google Cloud pricing and responsibilities involved with managing database instances',
  ),
  cancelLabel: s__('CloudSeed|Cancel'),
  submitLabel: s__('CloudSeed|Create instance'),
  all: s__('CloudSeed|All'),
};

export default {
  ALL_REFS: '*',
  components: {
    GlButton,
    GlFormCheckbox,
    GlFormGroup,
    GlFormSelect,
  },
  props: {
    cancelPath: { required: true, type: String },
    gcpProjects: { required: true, type: Array },
    refs: { required: true, type: Array },
    formTitle: { required: true, type: String },
    formDescription: { required: true, type: String },
    databaseVersions: { required: true, type: Array },
    tiers: { required: true, type: Array },
  },
  i18n,
};
</script>
<template>
  <div>
    <header class="gl-my-5 gl-border-b-1 gl-border-b-default gl-border-b-solid">
      <h2 class="gl-text-size-h1">{{ formTitle }}</h2>
      <p>{{ formDescription }}</p>
    </header>

    <gl-form-group
      data-testid="form_group_gcp_project"
      label-for="gcp_project"
      :label="$options.i18n.gcpProjectLabel"
      :description="$options.i18n.gcpProjectDescription"
    >
      <gl-form-select id="gcp_project" data-testid="select_gcp_project" name="gcp_project" required>
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
      data-testid="form_group_environments"
      label-for="ref"
      :label="$options.i18n.refsLabel"
      :description="$options.i18n.refsDescription"
    >
      <gl-form-select id="ref" data-testid="select_environments" name="ref" required>
        <option :value="$options.ALL_REFS">{{ $options.i18n.all }}</option>
        <option v-for="ref in refs" :key="ref" :value="ref">
          {{ ref }}
        </option>
      </gl-form-select>
    </gl-form-group>

    <gl-form-group
      data-testid="form_group_tier"
      label-for="tier"
      :label="$options.i18n.tierLabel"
      :description="$options.i18n.tierDescription"
    >
      <gl-form-select id="tier" data-testid="select_tier" name="tier" required>
        <option v-for="tier in tiers" :key="tier.value" :value="tier.value">
          {{ tier.label }}
        </option>
      </gl-form-select>
    </gl-form-group>

    <gl-form-group
      data-testid="form_group_database_version"
      label-for="database-version"
      :label="$options.i18n.databaseVersionLabel"
    >
      <gl-form-select
        id="database-version"
        data-testid="select_database_version"
        name="database_version"
        required
      >
        <option
          v-for="databaseVersion in databaseVersions"
          :key="databaseVersion.value"
          :value="databaseVersion.value"
        >
          {{ databaseVersion.label }}
        </option>
      </gl-form-select>
    </gl-form-group>

    <gl-form-group>
      <gl-form-checkbox name="confirmation" required>
        {{ $options.i18n.checkboxLabel }}
      </gl-form-checkbox>
    </gl-form-group>

    <div class="form-actions row">
      <gl-button type="submit" category="primary" variant="confirm" data-testid="submit-button">
        {{ $options.i18n.submitLabel }}
      </gl-button>
      <gl-button class="gl-ml-1" :href="cancelPath" data-testid="cancel-button">{{
        $options.i18n.cancelLabel
      }}</gl-button>
    </div>
  </div>
</template>

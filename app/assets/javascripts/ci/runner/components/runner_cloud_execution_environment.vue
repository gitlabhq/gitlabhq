<script>
import {
  GlCollapsibleListbox,
  GlFormGroup,
  GlLink,
  GlIcon,
  GlPopover,
  GlSprintf,
} from '@gitlab/ui';
import { s__ } from '~/locale';
import RunnerCreateFormNew from '~/ci/runner/components/runner_create_form_new.vue';

import { PROJECT_TYPE, RUNNER_TYPES } from '../constants';

export default {
  components: {
    GlCollapsibleListbox,
    GlFormGroup,
    GlIcon,
    GlLink,
    GlPopover,
    GlSprintf,
    RunnerCreateFormNew,
  },
  props: {
    projectId: {
      type: String,
      required: false,
      default: null,
    },
    groupId: {
      type: String,
      required: false,
      default: null,
    },
    runnerType: {
      type: String,
      required: true,
      validator: (t) => RUNNER_TYPES.includes(t),
    },
  },
  data() {
    return {
      regions: [
        {
          text: 'us-central-1',
          value: 'us-central-1',
        },
      ],
      selectedRegion: 'us-central-1',
      zones: [
        {
          text: 'us-central-1a',
          value: 'us-central-1a',
        },
      ],
      selectedZone: 'us-central-1a',
      machineTypes: [
        {
          text: 'n2d-standard-2 (2 vCPU, 1 core, 8 GB memory)',
          value: 'n2d-standard-2 (2 vCPU, 1 core, 8 GB memory)',
        },
      ],
      selectedMachineType: 'n2d-standard-2 (2 vCPU, 1 core, 8 GB memory)',
    };
  },
  methods: {
    onSubmit(runnerDetails) {
      this.$emit('submit', {
        selectedRegion: this.selectedRegion,
        selectedZone: this.selectedZone,
        selectedMachineType: this.selectedMachineType,
        ...runnerDetails,
      });
    },
    onPrevious(runnerDetails) {
      this.$emit('previous', {
        selectedRegion: this.selectedRegion,
        selectedZone: this.selectedZone,
        selectedMachineType: this.selectedMachineType,
        ...runnerDetails,
      });
    },
  },
  i18n: {
    executionEnvironment: s__('Runners|Execution environment'),
    executionEnvironmentDescription: s__(
      'Runners|Runners are created based on demand, in temporary virtual machine (VM) instances. The VMs use the Google Container-Optimized OS and Docker Engine with support for auto-scaling',
    ),
    regionLabel: s__('Runners|Region'),
    regionHelpText: s__('Runners|Specific geographical location where you can run your resources.'),
    zoneLabel: s__('Runners|Zone'),
    zoneHelpText: s__(
      'Runners|Isolated location within a region. The zone determines what computing resources are available and where your data is stored and used.',
    ),
    machineTypeLabel: s__('Runners|Machine type'),
    machineTypeHelpText: s__(
      'Runners|Machine type with preset amounts of virtual machines processors (vCPUs) and memory',
    ),
    learnMore: s__('Runners|Learn more in the %{linkStart}Google Cloud documentation%{linkEnd}.'),
  },
  links: {
    regionAndZonesLink: 'https://cloud.google.com/compute/docs/regions-zones',
  },
  PROJECT_TYPE,
};
</script>
<template>
  <div>
    <div class="row gl-mx-0">
      <div class="col-8 gl-px-0">
        <h3>{{ $options.i18n.executionEnvironment }}</h3>
        <p>{{ $options.i18n.executionEnvironmentDescription }}</p>
        <gl-form-group label-for="region-id">
          <template #label>
            <div class="gl-mb-3">
              {{ $options.i18n.regionLabel
              }}<gl-icon id="region-popover" class="gl-ml-2" name="question-o" />
              <gl-popover triggers="hover" placement="top" target="region-popover">
                <template #default>
                  <p>{{ $options.i18n.regionHelpText }}</p>
                  <gl-sprintf :message="$options.i18n.learnMore">
                    <template #link="{ content }">
                      <gl-link :href="$options.links.regionAndZonesLink" target="_blank">
                        {{ content }}<gl-icon name="external-link" />
                      </gl-link>
                    </template>
                  </gl-sprintf>
                </template>
              </gl-popover>
            </div>
          </template>
          <gl-collapsible-listbox
            id="region-id"
            :selected="selectedRegion"
            :items="regions"
            :toggle-text="selectedRegion"
            block
            data-testid="region-dropdown"
          />
        </gl-form-group>
        <gl-form-group label-for="zone-id">
          <template #label>
            <div class="gl-mb-3">
              {{ $options.i18n.zoneLabel
              }}<gl-icon id="zone-popover" class="gl-ml-2" name="question-o" />
              <gl-popover triggers="hover" placement="top" target="zone-popover">
                <template #default>
                  <p>{{ $options.i18n.zoneHelpText }}</p>
                  <gl-sprintf :message="$options.i18n.learnMore">
                    <template #link="{ content }">
                      <gl-link :href="$options.links.regionAndZonesLink" target="_blank">
                        {{ content }}<gl-icon name="external-link" />
                      </gl-link>
                    </template>
                  </gl-sprintf>
                </template>
              </gl-popover>
            </div>
          </template>
          <gl-collapsible-listbox
            :selected="selectedZone"
            :items="zones"
            :toggle-text="selectedZone"
            block
            data-testid="zone-dropdown"
          />
        </gl-form-group>
        <gl-form-group label-for="machine-type-id">
          <template #label>
            <div class="gl-mb-3">
              {{ $options.i18n.machineTypeLabel
              }}<gl-icon id="machine-type-popover" class="gl-ml-2" name="question-o" />
              <gl-popover triggers="hover" placement="top" target="machine-type-popover">
                <template #default>
                  {{ $options.i18n.machineTypeHelpText }}
                </template>
              </gl-popover>
            </div>
          </template>
          <gl-collapsible-listbox
            :selected="selectedMachineType"
            :items="machineTypes"
            :toggle-text="selectedMachineType"
            block
            data-testid="machine-type-dropdown"
          />
        </gl-form-group>
      </div>
    </div>
    <div class="row gl-mx-0">
      <runner-create-form-new
        :runner-type="runnerType"
        :group-id="groupId"
        @createRunner="onSubmit"
        @previous="onPrevious"
      />
    </div>
  </div>
</template>

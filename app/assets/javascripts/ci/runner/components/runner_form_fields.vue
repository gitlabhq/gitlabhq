<script>
import { isEqual } from 'lodash';
import {
  GlFormGroup,
  GlFormCheckbox,
  GlFormInput,
  GlIcon,
  GlLink,
  GlSprintf,
  GlSkeletonLoader,
} from '@gitlab/ui';
import SettingsSection from '~/vue_shared/components/settings/settings_section.vue';
import { helpPagePath } from '~/helpers/help_page_helper';
import {
  ACCESS_LEVEL_NOT_PROTECTED,
  ACCESS_LEVEL_REF_PROTECTED,
  PROJECT_TYPE,
  RUNNER_TYPES,
} from '../constants';

export default {
  name: 'RunnerFormFields',
  components: {
    GlFormGroup,
    GlFormCheckbox,
    GlFormInput,
    GlIcon,
    GlLink,
    GlSprintf,
    GlSkeletonLoader,
    SettingsSection,
    RunnerMaintenanceNoteField: () =>
      import('ee_component/ci/runner/components/runner_maintenance_note_field.vue'),
  },
  props: {
    runnerType: {
      type: String,
      required: false,
      default: null,
      validator: (t) => RUNNER_TYPES.includes(t),
    },
    value: {
      type: Object,
      default: null,
      required: false,
    },
    loading: {
      type: Boolean,
      default: false,
      required: false,
    },
  },
  data() {
    return {
      model: null,
    };
  },
  computed: {
    canBeLockedToProject() {
      return this.runnerType === PROJECT_TYPE;
    },
  },
  watch: {
    value: {
      handler(newVal, oldVal) {
        // update only when values change, avoids infinite loop
        if (!isEqual(newVal, oldVal)) {
          this.model = { ...newVal };
        }
      },
      immediate: true,
    },
    model: {
      handler() {
        this.$emit('input', this.model);
      },
      deep: true,
    },
  },
  HELP_LABELS_PAGE_PATH: helpPagePath('ci/runners/configure_runners', {
    anchor: 'control-jobs-that-a-runner-can-run',
  }),
  ACCESS_LEVEL_NOT_PROTECTED,
  ACCESS_LEVEL_REF_PROTECTED,
};
</script>
<template>
  <div>
    <settings-section :heading="s__('Runners|Tags')">
      <gl-skeleton-loader v-if="loading" :lines="16" />
      <template v-else-if="model">
        <gl-form-group :label="__('Tags')" label-for="runner-tags">
          <template #description>
            <gl-sprintf
              :message="
                s__('Runners|Separate multiple tags with a comma. For example, %{example}.')
              "
            >
              <template #example>
                <!-- eslint-disable-next-line @gitlab/vue-require-i18n-strings -->
                <code>macos, shared</code>
              </template>
            </gl-sprintf>
          </template>
          <template #label-description>
            <gl-sprintf
              :message="
                s__(
                  'Runners|Add tags to specify jobs that the runner can run. %{helpLinkStart}Learn more%{helpLinkEnd}.',
                )
              "
            >
              <template #helpLink="{ content }">
                <gl-link :href="$options.HELP_LABELS_PAGE_PATH" target="_blank">{{
                  content
                }}</gl-link>
              </template>
            </gl-sprintf>
          </template>
          <gl-form-input id="runner-tags" v-model="model.tagList" name="tags" />
        </gl-form-group>
        <gl-form-checkbox v-model="model.runUntagged" name="run-untagged">
          {{ __('Run untagged jobs') }}
          <template #help>
            {{ s__('Runners|Use the runner for jobs without tags in addition to tagged jobs.') }}
          </template>
        </gl-form-checkbox>
      </template>
    </settings-section>

    <settings-section>
      <template #heading>
        {{ s__('Runners|Configuration') }}
        {{ __('(optional)') }}
      </template>

      <gl-skeleton-loader v-if="loading" :lines="24" />
      <template v-else-if="model">
        <gl-form-group :label="s__('Runners|Runner description')" label-for="runner-description">
          <gl-form-input id="runner-description" v-model="model.description" name="description" />
        </gl-form-group>
        <runner-maintenance-note-field v-model="model.maintenanceNote" class="gl-mt-5" />

        <div class="gl-mb-5">
          <gl-form-checkbox v-model="model.paused" name="paused">
            {{ __('Paused') }}
            <template #help>
              {{ s__('Runners|Stop the runner from accepting new jobs.') }}
            </template>
          </gl-form-checkbox>

          <gl-form-checkbox
            v-model="model.accessLevel"
            name="protected"
            :value="$options.ACCESS_LEVEL_REF_PROTECTED"
            :unchecked-value="$options.ACCESS_LEVEL_NOT_PROTECTED"
          >
            {{ __('Protected') }}
            <template #help>
              {{ s__('Runners|Use the runner on pipelines for protected branches only.') }}
            </template>
          </gl-form-checkbox>

          <gl-form-checkbox v-if="canBeLockedToProject" v-model="model.locked" name="locked">
            {{ __('Lock to current projects') }} <gl-icon name="lock" />
            <template #help>
              {{
                s__(
                  'Runners|Use the runner for the currently assigned projects only. Only administrators can change the assigned projects.',
                )
              }}
            </template>
          </gl-form-checkbox>
        </div>

        <gl-form-group
          :label="__('Maximum job timeout')"
          :label-description="
            s__(
              'Runners|Maximum amount of time the runner can run before it terminates. If a project has a shorter job timeout period, the job timeout period of the instance runner is used instead.',
            )
          "
          label-for="runner-max-timeout"
          :description="
            s__('Runners|Enter the job timeout in seconds. Must be a minimum of 600 seconds.')
          "
        >
          <gl-form-input
            id="runner-max-timeout"
            v-model.number="model.maximumTimeout"
            name="max-timeout"
            type="number"
          />
        </gl-form-group>
      </template>
    </settings-section>
  </div>
</template>

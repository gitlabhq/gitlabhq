<script>
import {
  GlButton,
  GlDropdown,
  GlDropdownItem,
  GlFormCheckbox,
  GlForm,
  GlFormGroup,
  GlFormInput,
  GlFormTextarea,
} from '@gitlab/ui';
import { __, s__ } from '~/locale';
import { createAlert } from '~/alert';
import { visitUrl } from '~/lib/utils/url_utility';
import { REF_TYPE_BRANCHES, REF_TYPE_TAGS } from '~/ref/constants';
import RefSelector from '~/ref/components/ref_selector.vue';
import TimezoneDropdown from '~/vue_shared/components/timezone_dropdown/timezone_dropdown.vue';
import IntervalPatternInput from '~/pages/projects/pipeline_schedules/shared/components/interval_pattern_input.vue';
import createPipelineScheduleMutation from '../graphql/mutations/create_pipeline_schedule.mutation.graphql';
import { VARIABLE_TYPE, FILE_TYPE } from '../constants';

export default {
  components: {
    GlButton,
    GlDropdown,
    GlDropdownItem,
    GlForm,
    GlFormCheckbox,
    GlFormGroup,
    GlFormInput,
    GlFormTextarea,
    RefSelector,
    TimezoneDropdown,
    IntervalPatternInput,
  },
  inject: [
    'fullPath',
    'projectId',
    'defaultBranch',
    'cron',
    'cronTimezone',
    'dailyLimit',
    'settingsLink',
    'schedulesPath',
  ],
  props: {
    timezoneData: {
      type: Array,
      required: true,
    },
    refParam: {
      type: String,
      required: false,
      default: '',
    },
    editing: {
      type: Boolean,
      required: true,
    },
  },
  data() {
    return {
      cronValue: this.cron,
      description: '',
      scheduleRef: this.defaultBranch,
      activated: true,
      timezone: this.cronTimezone,
      variables: [],
    };
  },
  i18n: {
    activated: __('Activated'),
    cronTimezone: s__('PipelineSchedules|Cron timezone'),
    description: s__('PipelineSchedules|Description'),
    shortDescriptionPipeline: s__(
      'PipelineSchedules|Provide a short description for this pipeline',
    ),
    savePipelineSchedule: s__('PipelineSchedules|Save pipeline schedule'),
    cancel: __('Cancel'),
    targetBranchTag: __('Select target branch or tag'),
    intervalPattern: s__('PipelineSchedules|Interval Pattern'),
    variablesDescription: s__(
      'Pipeline|Specify variable values to be used in this run. The values specified in %{linkStart}CI/CD settings%{linkEnd} will be used by default.',
    ),
    removeVariableLabel: s__('CiVariables|Remove variable'),
    variables: s__('Pipeline|Variables'),
    scheduleCreateError: s__(
      'PipelineSchedules|An error occurred while creating the pipeline schedule.',
    ),
  },
  typeOptions: {
    [VARIABLE_TYPE]: __('Variable'),
    [FILE_TYPE]: __('File'),
  },
  formElementClasses: 'gl-md-mr-3 gl-mb-3 gl-flex-basis-quarter gl-flex-shrink-0 gl-flex-grow-0',
  computed: {
    dropdownTranslations() {
      return {
        dropdownHeader: this.$options.i18n.targetBranchTag,
      };
    },
    typeOptionsListbox() {
      return [
        {
          text: __('Variable'),
          value: VARIABLE_TYPE,
        },
        {
          text: __('File'),
          value: FILE_TYPE,
        },
      ];
    },
    getEnabledRefTypes() {
      return [REF_TYPE_BRANCHES, REF_TYPE_TAGS];
    },
    preparedVariables() {
      return this.variables.filter((variable) => variable.key !== '');
    },
  },
  created() {
    this.addEmptyVariable();
  },
  methods: {
    addEmptyVariable() {
      const lastVar = this.variables[this.variables.length - 1];

      if (lastVar?.key === '' && lastVar?.value === '') {
        return;
      }

      this.variables.push({
        variableType: VARIABLE_TYPE,
        key: '',
        value: '',
      });
    },
    setVariableAttribute(key, attribute, value) {
      const variable = this.variables.find((v) => v.key === key);
      variable[attribute] = value;
    },
    removeVariable(index) {
      this.variables.splice(index, 1);
    },
    canRemove(index) {
      return index < this.variables.length - 1;
    },
    scheduleHandler() {
      if (!this.editing) {
        this.createPipelineSchedule();
      }
    },
    async createPipelineSchedule() {
      try {
        const {
          data: {
            pipelineScheduleCreate: { errors },
          },
        } = await this.$apollo.mutate({
          mutation: createPipelineScheduleMutation,
          variables: {
            input: {
              description: this.description,
              cron: this.cronValue,
              cronTimezone: this.timezone,
              ref: this.scheduleRef,
              variables: this.preparedVariables,
              active: this.activated,
              projectPath: this.fullPath,
            },
          },
        });

        if (errors.length > 0) {
          createAlert({ message: errors[0] });
        } else {
          visitUrl(this.schedulesPath);
        }
      } catch {
        createAlert({ message: this.$options.i18n.scheduleCreateError });
      }
    },
    setCronValue(cron) {
      this.cronValue = cron;
    },
    setTimezone(timezone) {
      this.timezone = timezone.identifier || '';
    },
  },
};
</script>

<template>
  <div class="col-lg-8 gl-pl-0">
    <gl-form>
      <!--Description-->
      <gl-form-group :label="$options.i18n.description" label-for="schedule-description">
        <gl-form-input
          id="schedule-description"
          v-model="description"
          type="text"
          :placeholder="$options.i18n.shortDescriptionPipeline"
          data-testid="schedule-description"
          required
        />
      </gl-form-group>
      <!--Interval Pattern-->
      <gl-form-group :label="$options.i18n.intervalPattern" label-for="schedule-interval">
        <interval-pattern-input
          id="schedule-interval"
          :initial-cron-interval="cron"
          :daily-limit="dailyLimit"
          :send-native-errors="false"
          @cronValue="setCronValue"
        />
      </gl-form-group>
      <!--Timezone-->
      <gl-form-group :label="$options.i18n.cronTimezone" label-for="schedule-timezone">
        <timezone-dropdown
          id="schedule-timezone"
          :value="timezone"
          :timezone-data="timezoneData"
          name="schedule-timezone"
          @input="setTimezone"
        />
      </gl-form-group>
      <!--Branch/Tag Selector-->
      <gl-form-group :label="$options.i18n.targetBranchTag" label-for="schedule-target-branch-tag">
        <ref-selector
          id="schedule-target-branch-tag"
          v-model="scheduleRef"
          :enabled-ref-types="getEnabledRefTypes"
          :project-id="projectId"
          :value="scheduleRef"
          :use-symbolic-ref-names="true"
          :translations="dropdownTranslations"
          class="gl-w-full"
        />
      </gl-form-group>
      <!--Variable List-->
      <gl-form-group :label="$options.i18n.variables">
        <div
          v-for="(variable, index) in variables"
          :key="`var-${index}`"
          class="gl-mb-3 gl-pb-2"
          data-testid="ci-variable-row"
          data-qa-selector="ci_variable_row_container"
        >
          <div
            class="gl-display-flex gl-align-items-stretch gl-flex-direction-column gl-md-flex-direction-row"
          >
            <gl-dropdown
              :text="$options.typeOptions[variable.variableType]"
              :class="$options.formElementClasses"
              data-testid="pipeline-form-ci-variable-type"
            >
              <gl-dropdown-item
                v-for="type in Object.keys($options.typeOptions)"
                :key="type"
                @click="setVariableAttribute(variable.key, 'variableType', type)"
              >
                {{ $options.typeOptions[type] }}
              </gl-dropdown-item>
            </gl-dropdown>
            <gl-form-input
              v-model="variable.key"
              :placeholder="s__('CiVariables|Input variable key')"
              :class="$options.formElementClasses"
              data-testid="pipeline-form-ci-variable-key"
              data-qa-selector="ci_variable_key_field"
              @change="addEmptyVariable()"
            />

            <gl-form-textarea
              v-model="variable.value"
              :placeholder="s__('CiVariables|Input variable value')"
              class="gl-mb-3 gl-h-7!"
              :style="$options.textAreaStyle"
              :no-resize="false"
              data-testid="pipeline-form-ci-variable-value"
              data-qa-selector="ci_variable_value_field"
            />

            <template v-if="variables.length > 1">
              <gl-button
                v-if="canRemove(index)"
                class="gl-md-ml-3 gl-mb-3"
                data-testid="remove-ci-variable-row"
                variant="danger"
                category="secondary"
                icon="clear"
                :aria-label="$options.i18n.removeVariableLabel"
                @click="removeVariable(index)"
              />
              <gl-button
                v-else
                class="gl-md-ml-3 gl-mb-3 gl-display-none gl-md-display-block gl-visibility-hidden"
                icon="clear"
                :aria-label="$options.i18n.removeVariableLabel"
              />
            </template>
          </div>
        </div>
      </gl-form-group>
      <!--Activated-->
      <gl-form-checkbox id="schedule-active" v-model="activated" class="gl-mb-3">
        {{ $options.i18n.activated }}
      </gl-form-checkbox>

      <gl-button variant="confirm" data-testid="schedule-submit-button" @click="scheduleHandler">
        {{ $options.i18n.savePipelineSchedule }}
      </gl-button>
      <gl-button :href="schedulesPath" data-testid="schedule-cancel-button">
        {{ $options.i18n.cancel }}
      </gl-button>
    </gl-form>
  </div>
</template>

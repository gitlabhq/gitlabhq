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
  GlLink,
  GlSprintf,
} from '@gitlab/ui';
import { uniqueId } from 'lodash';
import Vue from 'vue';
import { __, s__ } from '~/locale';
import { REF_TYPE_BRANCHES, REF_TYPE_TAGS } from '~/ref/constants';
import RefSelector from '~/ref/components/ref_selector.vue';
import TimezoneDropdown from '~/vue_shared/components/timezone_dropdown/timezone_dropdown.vue';
import IntervalPatternInput from '~/pages/projects/pipeline_schedules/shared/components/interval_pattern_input.vue';
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
    GlLink,
    GlSprintf,
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
  },
  data() {
    return {
      refValue: {
        shortName: this.refParam,
        // this is needed until we add support for ref type in url query strings
        // ensure default branch is called with full ref on load
        // https://gitlab.com/gitlab-org/gitlab/-/issues/287815
        fullName: this.refParam === this.defaultBranch ? `refs/heads/${this.refParam}` : undefined,
      },
      description: '',
      scheduleRef: this.defaultBranch,
      activated: true,
      timezone: this.cronTimezone,
      formCiVariables: {},
      // TODO: Add the GraphQL query to help populate the predefined variables
      // app/assets/javascripts/ci/pipeline_new/components/pipeline_new_form.vue#131
      predefinedValueOptions: {},
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
    refFullName() {
      return this.refValue.fullName;
    },
    variables() {
      return this.formCiVariables[this.refFullName]?.variables ?? [];
    },
    descriptions() {
      return this.formCiVariables[this.refFullName]?.descriptions ?? {};
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
  },
  created() {
    Vue.set(this.formCiVariables, this.refFullName, {
      variables: [],
      descriptions: {},
    });

    this.addEmptyVariable(this.refFullName);
  },
  methods: {
    addEmptyVariable(refValue) {
      const { variables } = this.formCiVariables[refValue];

      const lastVar = variables[variables.length - 1];
      if (lastVar?.key === '' && lastVar?.value === '') {
        return;
      }

      variables.push({
        uniqueId: uniqueId(`var-${refValue}`),
        variable_type: VARIABLE_TYPE,
        key: '',
        value: '',
      });
    },
    setVariableAttribute(key, attribute, value) {
      const { variables } = this.formCiVariables[this.refFullName];
      const variable = variables.find((v) => v.key === key);
      variable[attribute] = value;
    },
    shouldShowValuesDropdown(key) {
      return this.predefinedValueOptions[key]?.length > 1;
    },
    removeVariable(index) {
      this.variables.splice(index, 1);
    },
    canRemove(index) {
      return index < this.variables.length - 1;
    },
  },
};
</script>

<template>
  <div class="col-lg-8">
    <gl-form>
      <!--Description-->
      <gl-form-group :label="$options.i18n.description" label-for="schedule-description">
        <gl-form-input
          id="schedule-description"
          v-model="description"
          type="text"
          :placeholder="$options.i18n.shortDescriptionPipeline"
          data-testid="schedule-description"
        />
      </gl-form-group>
      <!--Interval Pattern-->
      <gl-form-group :label="$options.i18n.intervalPattern" label-for="schedule-interval">
        <interval-pattern-input
          id="schedule-interval"
          :initial-cron-interval="cron"
          :daily-limit="dailyLimit"
          :send-native-errors="false"
        />
      </gl-form-group>
      <!--Timezone-->
      <gl-form-group :label="$options.i18n.cronTimezone" label-for="schedule-timezone">
        <timezone-dropdown
          id="schedule-timezone"
          :value="timezone"
          :timezone-data="timezoneData"
          name="schedule-timezone"
        />
      </gl-form-group>
      <!--Branch/Tag Selector-->
      <gl-form-group :label="$options.i18n.targetBranchTag" label-for="schedule-target-branch-tag">
        <ref-selector
          id="schedule-target-branch-tag"
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
          :key="variable.uniqueId"
          class="gl-mb-3 gl-pb-2"
          data-testid="ci-variable-row"
          data-qa-selector="ci_variable_row_container"
        >
          <div
            class="gl-display-flex gl-align-items-stretch gl-flex-direction-column gl-md-flex-direction-row"
          >
            <gl-dropdown
              :text="$options.typeOptions[variable.variable_type]"
              :class="$options.formElementClasses"
              data-testid="pipeline-form-ci-variable-type"
            >
              <gl-dropdown-item
                v-for="type in Object.keys($options.typeOptions)"
                :key="type"
                @click="setVariableAttribute(variable.key, 'variable_type', type)"
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
              @change="addEmptyVariable(refFullName)"
            />
            <gl-dropdown
              v-if="shouldShowValuesDropdown(variable.key)"
              :text="variable.value"
              :class="$options.formElementClasses"
              class="gl-flex-grow-1 gl-mr-0!"
              data-testid="pipeline-form-ci-variable-value-dropdown"
            >
              <gl-dropdown-item
                v-for="value in predefinedValueOptions[variable.key]"
                :key="value"
                data-testid="pipeline-form-ci-variable-value-dropdown-items"
                @click="setVariableAttribute(variable.key, 'value', value)"
              >
                {{ value }}
              </gl-dropdown-item>
            </gl-dropdown>
            <gl-form-textarea
              v-else
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
          <div v-if="descriptions[variable.key]" class="gl-text-gray-500 gl-mb-3">
            {{ descriptions[variable.key] }}
          </div>
        </div>

        <template #description
          ><gl-sprintf :message="$options.i18n.variablesDescription">
            <template #link="{ content }">
              <gl-link :href="settingsLink">{{ content }}</gl-link>
            </template>
          </gl-sprintf></template
        >
      </gl-form-group>
      <!--Activated-->
      <gl-form-checkbox id="schedule-active" v-model="activated" class="gl-mb-3">{{
        $options.i18n.activated
      }}</gl-form-checkbox>

      <gl-button type="submit" variant="confirm" data-testid="schedule-submit-button">{{
        $options.i18n.savePipelineSchedule
      }}</gl-button>
      <gl-button type="reset" data-testid="schedule-cancel-button">{{
        $options.i18n.cancel
      }}</gl-button>
    </gl-form>
  </div>
</template>

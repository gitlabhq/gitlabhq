<script>
import {
  GlButton,
  GlCollapsibleListbox,
  GlFormCheckbox,
  GlForm,
  GlFormGroup,
  GlFormInput,
  GlFormTextarea,
  GlLoadingIcon,
} from '@gitlab/ui';
import { __, s__ } from '~/locale';
import { createAlert } from '~/alert';
import { visitUrl, queryToObject } from '~/lib/utils/url_utility';
import { REF_TYPE_BRANCHES, REF_TYPE_TAGS } from '~/ref/constants';
import RefSelector from '~/ref/components/ref_selector.vue';
import TimezoneDropdown from '~/vue_shared/components/timezone_dropdown/timezone_dropdown.vue';
import IntervalPatternInput from '~/pages/projects/pipeline_schedules/shared/components/interval_pattern_input.vue';
import createPipelineScheduleMutation from '../graphql/mutations/create_pipeline_schedule.mutation.graphql';
import updatePipelineScheduleMutation from '../graphql/mutations/update_pipeline_schedule.mutation.graphql';
import getPipelineSchedulesQuery from '../graphql/queries/get_pipeline_schedules.query.graphql';
import { VARIABLE_TYPE, FILE_TYPE } from '../constants';

const scheduleId = queryToObject(window.location.search).id;

export default {
  components: {
    GlButton,
    GlCollapsibleListbox,
    GlForm,
    GlFormCheckbox,
    GlFormGroup,
    GlFormInput,
    GlFormTextarea,
    GlLoadingIcon,
    RefSelector,
    TimezoneDropdown,
    IntervalPatternInput,
  },
  inject: ['fullPath', 'projectId', 'defaultBranch', 'dailyLimit', 'settingsLink', 'schedulesPath'],
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
  apollo: {
    schedule: {
      query: getPipelineSchedulesQuery,
      variables() {
        return {
          projectPath: this.fullPath,
          ids: scheduleId,
        };
      },
      update(data) {
        return data.project?.pipelineSchedules?.nodes[0] || {};
      },
      result({ data }) {
        if (data) {
          const {
            project: {
              pipelineSchedules: { nodes },
            },
          } = data;

          const schedule = nodes[0];
          const variables = schedule.variables?.nodes || [];

          this.description = schedule.description;
          this.cron = schedule.cron;
          this.cronTimezone = schedule.cronTimezone;
          this.scheduleRef = schedule.ref || this.defaultBranch;
          this.variables = variables.map((variable) => {
            return {
              id: variable.id,
              variableType: variable.variableType,
              key: variable.key,
              value: variable.value,
              destroy: false,
            };
          });
          this.addEmptyVariable();
          this.activated = schedule.active;
        }
      },
      skip() {
        return !this.editing;
      },
      error() {
        createAlert({ message: this.$options.i18n.scheduleFetchError });
      },
    },
  },
  data() {
    return {
      cron: '',
      description: '',
      scheduleRef: this.defaultBranch,
      activated: true,
      cronTimezone: '',
      variables: [],
      schedule: {},
      showVarValues: false,
    };
  },
  i18n: {
    activated: __('Activated'),
    cronTimezoneText: s__('PipelineSchedules|Cron timezone'),
    description: s__('PipelineSchedules|Description'),
    shortDescriptionPipeline: s__(
      'PipelineSchedules|Provide a short description for this pipeline',
    ),
    saveScheduleBtnText: s__('PipelineSchedules|Save changes'),
    createScheduleBtnText: s__('PipelineSchedules|Create pipeline schedule'),
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
    scheduleUpdateError: s__(
      'PipelineSchedules|An error occurred while updating the pipeline schedule.',
    ),
    scheduleFetchError: s__(
      'PipelineSchedules|An error occurred while trying to fetch the pipeline schedule.',
    ),
    revealText: __('Reveal values'),
    hideText: __('Hide values'),
  },
  formElementClasses: 'md:gl-mr-3 gl-mb-3 gl-basis-1/4 gl-shrink-0 gl-flex-grow-0',
  // it's used to prevent the overwrite if 'gl-h-7' or '!gl-h-7' were used
  textAreaStyle: { height: '32px' },
  computed: {
    dropdownTranslations() {
      return {
        dropdownHeader: this.$options.i18n.targetBranchTag,
      };
    },
    typeOptions() {
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
    filledVariables() {
      return this.variables.filter((variable) => variable.key !== '' && !variable.empty);
    },
    preparedVariablesUpdate() {
      return this.filledVariables.map((variable) => {
        return {
          id: variable.id,
          key: variable.key,
          value: variable.value,
          variableType: variable.variableType,
          destroy: variable.destroy,
        };
      });
    },
    preparedVariablesCreate() {
      const vars = this.variables.filter((variable) => variable.key !== '');

      return vars.map((variable) => {
        return {
          key: variable.key,
          value: variable.value,
          variableType: variable.variableType,
        };
      });
    },
    loading() {
      return this.$apollo.queries.schedule.loading;
    },
    buttonText() {
      return this.editing
        ? this.$options.i18n.saveScheduleBtnText
        : this.$options.i18n.createScheduleBtnText;
    },
    varSecurityBtnText() {
      return this.showVarValues ? this.$options.i18n.hideText : this.$options.i18n.revealText;
    },
    hasExistingScheduleVariables() {
      return this.schedule?.variables?.nodes.length > 0;
    },
    showVarSecurityBtn() {
      return this.editing && this.hasExistingScheduleVariables;
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
        destroy: false,
        empty: true,
      });
    },
    setVariableType(typeValue, key) {
      const variable = this.variables.find((v) => v.key === key);
      variable.variableType = typeValue;
    },
    removeVariable(index) {
      this.variables[index].destroy = true;
    },
    canRemove(index) {
      return index < this.variables.length - 1;
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
              cron: this.cron,
              cronTimezone: this.cronTimezone,
              ref: this.scheduleRef,
              variables: this.preparedVariablesCreate,
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
    async updatePipelineSchedule() {
      try {
        const {
          data: {
            pipelineScheduleUpdate: { errors },
          },
        } = await this.$apollo.mutate({
          mutation: updatePipelineScheduleMutation,
          variables: {
            input: {
              id: this.schedule.id,
              description: this.description,
              cron: this.cron,
              cronTimezone: this.cronTimezone,
              ref: this.scheduleRef,
              variables: this.preparedVariablesUpdate,
              active: this.activated,
            },
          },
        });

        if (errors.length > 0) {
          createAlert({ message: errors[0] });
        } else {
          visitUrl(this.schedulesPath);
        }
      } catch {
        createAlert({ message: this.$options.i18n.scheduleUpdateError });
      }
    },
    scheduleHandler() {
      if (this.editing) {
        this.updatePipelineSchedule();
      } else {
        this.createPipelineSchedule();
      }
    },
    setCronValue(cron) {
      this.cron = cron;
    },
    setTimezone(timezone) {
      this.cronTimezone = timezone.identifier || '';
    },
    displayHiddenChars(variable) {
      return (
        this.editing && this.hasExistingScheduleVariables && !this.showVarValues && !variable.empty
      );
    },
    resetVariable(index) {
      this.variables[index].empty = false;
    },
  },
};
</script>

<template>
  <div class="col-lg-8 gl-pl-0">
    <gl-loading-icon v-if="loading && editing" size="lg" />
    <gl-form v-else>
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
      <!--Timezone-->
      <gl-form-group :label="$options.i18n.cronTimezoneText" label-for="schedule-timezone">
        <timezone-dropdown
          id="schedule-timezone"
          :value="cronTimezone"
          :timezone-data="timezoneData"
          name="schedule-timezone"
          @input="setTimezone"
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
      <gl-form-group class="gl-mb-0" :label="$options.i18n.variables">
        <div v-for="(variable, index) in variables" :key="`var-${index}`">
          <div
            v-if="!variable.destroy"
            class="gl-mb-3 gl-flex gl-flex-col gl-items-stretch gl-pb-2 md:gl-flex-row md:gl-items-start"
            data-testid="ci-variable-row"
          >
            <gl-collapsible-listbox
              :items="typeOptions"
              :selected="variable.variableType"
              :class="$options.formElementClasses"
              block
              data-testid="pipeline-form-ci-variable-type"
              @select="setVariableType($event, variable.key)"
            />

            <gl-form-input
              v-model="variable.key"
              :placeholder="s__('CiVariables|Input variable key')"
              :class="$options.formElementClasses"
              data-testid="pipeline-form-ci-variable-key"
              @change="addEmptyVariable(variable)"
            />

            <gl-form-textarea
              v-if="displayHiddenChars(variable)"
              value="*****************"
              disabled
              class="gl-mb-3 !gl-h-7"
              data-testid="pipeline-form-ci-variable-hidden-value"
            />

            <gl-form-textarea
              v-else
              v-model="variable.value"
              :placeholder="s__('CiVariables|Input variable value')"
              class="gl-mb-3 gl-min-h-7"
              :style="$options.textAreaStyle"
              :no-resize="false"
              data-testid="pipeline-form-ci-variable-value"
              @change="resetVariable(index)"
            />

            <template v-if="variables.length > 1">
              <gl-button
                v-if="canRemove(index)"
                class="gl-mb-3 md:gl-ml-3"
                data-testid="remove-ci-variable-row"
                variant="danger"
                category="secondary"
                icon="clear"
                :aria-label="$options.i18n.removeVariableLabel"
                @click="removeVariable(index)"
              />
              <gl-button
                v-else
                class="gl-invisible gl-mb-3 gl-hidden md:gl-ml-3 md:gl-block"
                icon="clear"
                :aria-label="$options.i18n.removeVariableLabel"
              />
            </template>
          </div>
        </div>
      </gl-form-group>

      <gl-button
        v-if="showVarSecurityBtn"
        class="gl-mb-5"
        category="secondary"
        variant="confirm"
        data-testid="variable-security-btn"
        @click="showVarValues = !showVarValues"
      >
        {{ varSecurityBtnText }}
      </gl-button>

      <!--Activated-->
      <gl-form-checkbox id="schedule-active" v-model="activated" class="gl-mb-3">
        {{ $options.i18n.activated }}
      </gl-form-checkbox>
      <div class="gl-flex gl-flex-wrap gl-gap-3">
        <gl-button
          variant="confirm"
          data-testid="schedule-submit-button"
          class="gl-w-full sm:gl-w-auto"
          @click="scheduleHandler"
        >
          {{ buttonText }}
        </gl-button>
        <gl-button
          :href="schedulesPath"
          data-testid="schedule-cancel-button"
          class="gl-w-full sm:gl-w-auto"
        >
          {{ $options.i18n.cancel }}
        </gl-button>
      </div>
    </gl-form>
  </div>
</template>

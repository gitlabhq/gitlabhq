<script>
import {
  GlLoadingIcon,
  GlFormInputGroup,
  GlInputGroupText,
  GlFormInput,
  GlButton,
  GlLink,
  GlSprintf,
  GlTooltipDirective,
  GlAnimatedChevronLgRightDownIcon,
  GlCollapse,
} from '@gitlab/ui';
import { cloneDeep, uniqueId } from 'lodash';
import { createAlert } from '~/alert';
import { reportToSentry } from '~/ci/utils';
import { JOB_GRAPHQL_ERRORS } from '~/ci/constants';
import { fetchPolicies } from '~/lib/graphql';
import { helpPagePath } from '~/helpers/help_page_helper';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import { TYPENAME_COMMIT_STATUS } from '~/graphql_shared/constants';
import GetJob from '../graphql/queries/get_job.query.graphql';

export default {
  name: 'JobVariablesForm',
  components: {
    GlLoadingIcon,
    GlFormInputGroup,
    GlInputGroupText,
    GlAnimatedChevronLgRightDownIcon,
    GlCollapse,
    GlFormInput,
    GlButton,
    GlLink,
    GlSprintf,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  clearBtnSharedClasses: ['gl-flex-grow-0 gl-basis-0 !gl-m-0 !gl-ml-3'],
  variableSettings: helpPagePath('ci/variables/_index', { anchor: 'for-a-project' }),
  inputTypes: {
    key: 'key',
    value: 'value',
  },
  inject: ['projectPath'],
  props: {
    jobId: {
      type: Number,
      required: true,
    },
    isExpanded: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  emits: ['update-variables'],
  apollo: {
    variables: {
      query: GetJob,
      variables() {
        return {
          fullPath: this.projectPath,
          id: convertToGraphQLId(TYPENAME_COMMIT_STATUS, this.jobId),
        };
      },
      skip() {
        // variables list always contains one empty variable
        // skip refetch if form already has non-empty variables
        return this.variables.length > 1;
      },
      fetchPolicy: fetchPolicies.CACHE_AND_NETWORK,
      update(data) {
        const jobVariables = cloneDeep(data?.project?.job?.manualVariables?.nodes);
        return [...jobVariables.reverse(), ...this.variables];
      },
      error(error) {
        createAlert({ message: JOB_GRAPHQL_ERRORS.jobQueryErrorText });
        reportToSentry(this.$options.name, error);
      },
    },
  },
  data() {
    return {
      variables: [
        {
          id: uniqueId(),
          key: '',
          value: '',
        },
      ],
      expanded: this.isExpanded,
    };
  },
  watch: {
    variables: {
      handler(newValue) {
        this.$emit('update-variables', newValue);
      },
      deep: true,
    },
  },
  methods: {
    inputRef(type, id) {
      return `${this.$options.inputTypes[type]}-${id}`;
    },
    addEmptyVariable() {
      const lastVar = this.variables[this.variables.length - 1];

      if (lastVar.key === '') {
        return;
      }

      this.variables.push({
        id: uniqueId(),
        key: '',
        value: '',
      });
    },
    canRemove(index) {
      return index < this.variables.length - 1;
    },
    deleteVariable(id) {
      this.variables.splice(
        this.variables.findIndex((el) => el.id === id),
        1,
      );
    },
  },
};
</script>
<template>
  <div class="gl-mt-5">
    <gl-button
      :aria-expanded="expanded"
      aria-controls="variables-form-collapse"
      category="tertiary"
      size="small"
      @click="expanded = !expanded"
    >
      <span class="gl-flex gl-items-center gl-gap-3 gl-text-size-h2 gl-font-bold">
        <gl-animated-chevron-lg-right-down-icon :is-on="expanded" />
        {{ s__('CiVariables|Variables') }}
      </span>
    </gl-button>

    <gl-collapse id="variables-form-collapse" :visible="expanded" class="gl-mx-auto gl-mt-5">
      <gl-loading-icon v-if="$apollo.queries.variables.loading" class="gl-mt-5" size="lg" />

      <div
        v-for="(variable, index) in variables"
        :key="variable.id"
        class="gl-mb-5 gl-flex gl-items-center"
        data-testid="ci-variable-row"
      >
        <gl-form-input-group class="gl-mr-4 gl-grow">
          <template #prepend>
            <gl-input-group-text>
              {{ s__('CiVariables|Key') }}
            </gl-input-group-text>
          </template>
          <gl-form-input
            :ref="inputRef('key', variable.id)"
            v-model="variable.key"
            :placeholder="s__('CiVariables|Input variable key')"
            data-testid="ci-variable-key"
            @change="addEmptyVariable"
          />
        </gl-form-input-group>

        <gl-form-input-group class="gl-grow-2">
          <template #prepend>
            <gl-input-group-text>
              {{ s__('CiVariables|Value') }}
            </gl-input-group-text>
          </template>
          <gl-form-input
            :ref="inputRef('value', variable.id)"
            v-model="variable.value"
            :placeholder="s__('CiVariables|Input variable value')"
            data-testid="ci-variable-value"
          />
        </gl-form-input-group>

        <gl-button
          v-if="canRemove(index)"
          v-gl-tooltip
          :aria-label="s__('CiVariables|Remove inputs')"
          :title="s__('CiVariables|Remove inputs')"
          :class="$options.clearBtnSharedClasses"
          category="tertiary"
          icon="remove"
          data-testid="delete-variable-btn"
          @click="deleteVariable(variable.id)"
        />
        <gl-button
          v-else
          aria-hidden="true"
          class="gl-pointer-events-none gl-opacity-0"
          :class="$options.clearBtnSharedClasses"
          data-testid="delete-variable-btn-placeholder"
          category="tertiary"
          icon="remove"
        />
      </div>

      <div class="gl-mt-5 gl-text-center">
        <gl-sprintf
          :message="
            s__(
              'CiVariables|Specify variable values to be used in this run. The variables specified in the configuration file and %{linkStart}CI/CD settings%{linkEnd} are used by default.',
            )
          "
        >
          <template #link="{ content }">
            <gl-link :href="$options.variableSettings" target="_blank">
              {{ content }}
            </gl-link>
          </template>
        </gl-sprintf>
      </div>
      <div class="gl-mt-3 gl-text-center">
        <gl-sprintf
          :message="
            s__(
              'CiVariables|Variables specified here are %{boldStart}expanded%{boldEnd} and not %{boldStart}masked.%{boldEnd}',
            )
          "
        >
          <template #bold="{ content }">
            <strong>
              {{ content }}
            </strong>
          </template>
        </gl-sprintf>
      </div>
    </gl-collapse>
  </div>
</template>

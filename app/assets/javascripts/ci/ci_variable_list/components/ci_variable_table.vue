<script>
import {
  GlAlert,
  GlBadge,
  GlButton,
  GlLoadingIcon,
  GlModalDirective,
  GlKeysetPagination,
  GlLink,
  GlTable,
  GlModal,
  GlTooltipDirective,
} from '@gitlab/ui';
import { __, s__, sprintf } from '~/locale';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import CrudComponent from '~/vue_shared/components/crud_component.vue';
import { convertEnvironmentScope } from '~/ci/common/private/ci_environments_dropdown';
import {
  DEFAULT_EXCEEDS_VARIABLE_LIMIT_TEXT,
  EXCEEDS_VARIABLE_LIMIT_TEXT,
  MAXIMUM_VARIABLE_LIMIT_REACHED,
  variableTypes,
} from '../constants';

export default {
  defaultFields: [
    {
      key: 'key',
      label: s__('CiVariables|Key'),
      sortable: true,
      thClass: 'gl-w-2/5',
    },
    {
      key: 'value',
      label: s__('CiVariables|Value'),
    },
    {
      key: 'environmentScope',
      label: s__('CiVariables|Environments'),
    },
    {
      key: 'actions',
      label: __('Actions'),
      thAlignRight: true,
      thClass: 'gl-w-15',
    },
  ],
  inheritedVarsFields: [
    {
      key: 'key',
      label: s__('CiVariables|Key'),
    },
    {
      key: 'environmentScope',
      label: s__('CiVariables|Environments'),
    },
    {
      key: 'group',
      label: s__('CiVariables|Group'),
    },
  ],
  components: {
    GlAlert,
    GlBadge,
    GlButton,
    GlKeysetPagination,
    GlLink,
    GlLoadingIcon,
    GlTable,
    GlModal,
    CrudComponent,
  },
  directives: {
    GlModalDirective,
    GlTooltip: GlTooltipDirective,
  },
  mixins: [glFeatureFlagsMixin()],
  inject: ['isInheritedGroupVars'],
  i18n: {
    title: s__('CiVariables|CI/CD Variables'),
    addButton: s__('CiVariables|Add variable'),
    editButton: __('Edit'),
    deleteButton: __('Delete'),
    modalDeleteTitle: s__('CiVariables|Delete variable'),
    modalDeleteMessage: s__('CiVariables|Do you want to delete the variable %{key}?'),
  },
  props: {
    entity: {
      type: String,
      required: false,
      default: '',
    },
    isLoading: {
      type: Boolean,
      required: true,
    },
    maxVariableLimit: {
      type: Number,
      required: true,
    },
    pageInfo: {
      type: Object,
      required: true,
    },
    variables: {
      type: Array,
      required: true,
    },
  },
  deleteModal: {
    actionPrimary: {
      text: __('Delete'),
      attributes: {
        variant: 'danger',
      },
    },
    actionSecondary: {
      text: __('Cancel'),
      attributes: {
        variant: 'default',
      },
    },
  },
  data() {
    return {
      areValuesHidden: true,
    };
  },
  computed: {
    exceedsVariableLimit() {
      return this.maxVariableLimit > 0 && this.variables.length >= this.maxVariableLimit;
    },
    exceedsVariableLimitText() {
      if (this.exceedsVariableLimit && this.entity) {
        return sprintf(EXCEEDS_VARIABLE_LIMIT_TEXT, {
          entity: this.entity,
          currentVariableCount: this.variables.length,
          maxVariableLimit: this.maxVariableLimit,
        });
      }

      return DEFAULT_EXCEEDS_VARIABLE_LIMIT_TEXT;
    },
    showAlert() {
      return !this.isLoading && this.exceedsVariableLimit;
    },
    showPagination() {
      return this.glFeatures.ciVariablesPages;
    },
    valuesButtonText() {
      return this.areValuesHidden ? __('Reveal values') : __('Hide values');
    },
    isTableEmpty() {
      return !this.variables || this.variables.length === 0;
    },
    fields() {
      return this.isInheritedGroupVars
        ? this.$options.inheritedVarsFields
        : this.$options.defaultFields;
    },
    tableDataTestId() {
      return this.isInheritedGroupVars ? 'inherited-ci-variable-table' : 'ci-variable-table';
    },
    variablesWithAttributes() {
      return this.variables?.map((item, index) => ({
        ...item,
        attributes: this.getAttributes(item),
        index,
      }));
    },
  },
  methods: {
    convertEnvironmentScopeValue(env) {
      return convertEnvironmentScope(env);
    },
    toggleHiddenState() {
      this.areValuesHidden = !this.areValuesHidden;
    },
    setSelectedVariable(index = -1) {
      this.$emit('set-selected-variable', this.variables[index] ?? null);
    },
    deleteSelectedVariable(index = -1) {
      this.$emit('delete-variable', this.variables[index] ?? null);
    },
    getAttributes(item) {
      const attributes = [];
      if (item.variableType === variableTypes.fileType) {
        attributes.push(s__('CiVariables|File'));
      }
      if (item.protected) {
        attributes.push(s__('CiVariables|Protected'));
      }
      if (item.masked) {
        attributes.push(s__('CiVariables|Masked'));
      }
      if (item.hidden) {
        attributes.push(s__('CiVariables|Hidden'));
      }
      if (!item.raw) {
        attributes.push(s__('CiVariables|Expanded'));
      }
      return attributes;
    },
    removeVariableMessage(key) {
      return sprintf(this.$options.i18n.modalDeleteMessage, {
        key,
      });
    },
  },
  maximumVariableLimitReached: MAXIMUM_VARIABLE_LIMIT_REACHED,
};
</script>

<template>
  <div>
    <crud-component
      :title="$options.i18n.title"
      :count="variables.length"
      icon="code"
      class="ci-variable-table"
      :data-testid="tableDataTestId"
    >
      <template #actions>
        <div v-if="!isInheritedGroupVars" class="gl-font-size-0">
          <gl-button
            v-if="!isTableEmpty"
            category="tertiary"
            size="small"
            class="gl-mr-3"
            @click="toggleHiddenState"
            >{{ valuesButtonText }}</gl-button
          >
          <gl-button
            size="small"
            :disabled="exceedsVariableLimit"
            data-testid="add-ci-variable-button"
            @click="setSelectedVariable()"
            >{{ $options.i18n.addButton }}</gl-button
          >
        </div>
      </template>

      <gl-loading-icon v-if="isLoading" class="gl-p-4" />
      <gl-alert
        v-if="showAlert"
        :dismissible="false"
        :title="$options.maximumVariableLimitReached"
        variant="info"
      >
        {{ exceedsVariableLimitText }}
      </gl-alert>
      <gl-table
        v-if="!isLoading"
        :fields="fields"
        :items="variablesWithAttributes"
        tbody-tr-class="js-ci-variable-row"
        sort-by="key"
        sort-direction="asc"
        stacked="md"
        fixed
        show-empty
        no-local-sorting
        @sort-changed="(val) => $emit('sort-changed', val)"
      >
        <template #table-colgroup="scope">
          <col v-for="field in scope.fields" :key="field.key" :style="field.customStyle" />
        </template>
        <template #cell(key)="{ item }">
          <div data-testid="ci-variable-table-row-variable">
            <div class="-gl-mr-3 gl-flex gl-items-start gl-justify-end md:gl-justify-start">
              <span
                :id="`ci-variable-key-${item.id}`"
                class="gl-inline-block gl-max-w-full gl-break-anywhere"
                >{{ item.key }}</span
              >
              <gl-button
                v-gl-tooltip
                category="tertiary"
                icon="copy-to-clipboard"
                class="-gl-my-2 gl-ml-2"
                size="small"
                :title="__('Copy key')"
                :data-clipboard-text="item.key"
                :aria-label="__('Copy to clipboard')"
              />
            </div>
            <div v-if="item.description" class="gl-mt-2 gl-text-sm gl-text-subtle">
              {{ item.description }}
            </div>
            <div data-testid="ci-variable-table-row-attributes" class="gl-mt-2">
              <gl-badge
                v-for="attribute in item.attributes"
                :key="`${item.key}-${attribute}`"
                class="gl-mr-2"
                variant="info"
              >
                {{ attribute }}
              </gl-badge>
            </div>
          </div>
        </template>
        <template v-if="!isInheritedGroupVars" #cell(value)="{ item }">
          <div
            v-if="!item.hidden"
            class="-gl-mr-3 gl-flex gl-items-start gl-justify-end md:gl-justify-start"
          >
            <span v-if="areValuesHidden" data-testid="hiddenValue">*****</span>
            <span
              v-else
              :id="`ci-variable-value-${item.id}`"
              class="gl-inline-block gl-max-w-full gl-truncate"
              data-testid="revealedValue"
              >{{ item.value }}</span
            >
            <gl-button
              v-gl-tooltip
              category="tertiary"
              icon="copy-to-clipboard"
              class="-gl-my-2 gl-ml-2"
              size="small"
              :title="__('Copy value')"
              :data-clipboard-text="item.value"
              :aria-label="__('Copy to clipboard')"
            />
          </div>
        </template>
        <template #cell(environmentScope)="{ item }">
          <div class="-gl-mr-3 gl-flex gl-items-start gl-justify-end md:gl-justify-start">
            <span
              :id="`ci-variable-env-${item.id}`"
              class="gl-inline-block gl-max-w-full gl-break-anywhere"
              >{{ convertEnvironmentScopeValue(item.environmentScope) }}</span
            >
            <gl-button
              v-gl-tooltip
              category="tertiary"
              icon="copy-to-clipboard"
              class="-gl-my-2 gl-ml-2"
              size="small"
              :title="__('Copy environment')"
              :data-clipboard-text="convertEnvironmentScopeValue(item.environmentScope)"
              :aria-label="__('Copy to clipboard')"
            />
          </div>
        </template>
        <template v-if="isInheritedGroupVars" #cell(group)="{ item }">
          <div class="-gl-mr-3 gl-flex gl-items-start gl-justify-end md:gl-justify-start">
            <gl-link
              :id="`ci-variable-group-${item.id}`"
              data-testid="ci-variable-table-row-cicd-path"
              class="gl-inline-block gl-max-w-full gl-break-anywhere"
              :href="item.groupCiCdSettingsPath"
            >
              {{ item.groupName }}
            </gl-link>
          </div>
        </template>
        <template v-if="!isInheritedGroupVars" #cell(actions)="{ item }">
          <div class="-gl-mb-2 -gl-mt-3 gl-flex gl-justify-end gl-gap-2">
            <gl-button
              v-gl-tooltip
              category="tertiary"
              icon="pencil"
              :title="$options.i18n.editButton"
              :aria-label="$options.i18n.editButton"
              data-testid="edit-ci-variable-button"
              @click="setSelectedVariable(item.index)"
            />
            <gl-button
              v-gl-tooltip
              v-gl-modal-directive="`delete-variable-${item.index}`"
              category="tertiary"
              icon="remove"
              :title="$options.i18n.deleteButton"
              :aria-label="$options.i18n.deleteButton"
            />
            <gl-modal
              ref="modal"
              :modal-id="`delete-variable-${item.index}`"
              :title="$options.i18n.modalDeleteTitle"
              :action-primary="$options.deleteModal.actionPrimary"
              :action-secondary="$options.deleteModal.actionSecondary"
              @primary="deleteSelectedVariable(item.index)"
            >
              {{ removeVariableMessage(item.key) }}
            </gl-modal>
          </div>
        </template>
        <template #empty>
          <p class="gl-mb-0 gl-py-1 gl-text-center gl-text-subtle">
            {{ __('There are no variables yet.') }}
          </p>
        </template>
      </gl-table>
      <gl-alert
        v-if="showAlert"
        :dismissible="false"
        :title="$options.maximumVariableLimitReached"
        variant="info"
      >
        {{ exceedsVariableLimitText }}
      </gl-alert>
    </crud-component>
    <div v-if="!isInheritedGroupVars">
      <div v-if="showPagination" class="gl-mt-5 gl-flex gl-justify-center">
        <gl-keyset-pagination
          v-bind="pageInfo"
          @prev="$emit('handle-prev-page')"
          @next="$emit('handle-next-page')"
        />
      </div>
    </div>
  </div>
</template>

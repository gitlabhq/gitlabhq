<script>
import {
  GlAlert,
  GlTooltipDirective,
  GlButton,
  GlFormInput,
  GlLink,
  GlLoadingIcon,
} from '@gitlab/ui';
import produce from 'immer';
import { createAlert } from '~/alert';
import { WORKSPACE_GROUP } from '~/issues/constants';
import { __ } from '~/locale';
import { workspaceLabelsQueries } from '../../../constants';
import createLabelMutation from './graphql/create_label.mutation.graphql';
import { DEFAULT_LABEL_COLOR } from './constants';

const errorMessage = __('Error creating label.');

export default {
  components: {
    GlAlert,
    GlButton,
    GlFormInput,
    GlLink,
    GlLoadingIcon,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    fullPath: {
      type: String,
      required: true,
    },
    attrWorkspacePath: {
      type: String,
      required: true,
    },
    labelCreateType: {
      type: String,
      required: true,
    },
    workspaceType: {
      type: String,
      required: true,
    },
    searchKey: {
      type: String,
      required: false,
      default: '',
    },
  },
  data() {
    return {
      labelTitle: this.searchKey,
      selectedColor: DEFAULT_LABEL_COLOR,
      labelCreateInProgress: false,
      error: undefined,
    };
  },
  computed: {
    disableCreate() {
      return !this.labelTitle.length || !this.selectedColor.length || this.labelCreateInProgress;
    },
    suggestedColors() {
      const colorsMap = gon.suggested_label_colors;
      return Object.keys(colorsMap).map((color) => ({ [color]: colorsMap[color] }));
    },
    mutationVariables() {
      const attributePath = this.labelCreateType === WORKSPACE_GROUP ? 'groupPath' : 'projectPath';

      return {
        title: this.labelTitle,
        color: this.selectedColor,
        [attributePath]: this.attrWorkspacePath,
      };
    },
  },
  methods: {
    getColorCode(color) {
      return Object.keys(color).pop();
    },
    getColorName(color) {
      return Object.values(color).pop();
    },
    handleColorClick(color) {
      this.selectedColor = this.getColorCode(color);
    },
    updateLabelsInCache(store, label) {
      const { query } = workspaceLabelsQueries[this.workspaceType];

      const sourceData = store.readQuery({
        query,
        variables: { fullPath: this.fullPath, searchTerm: '' },
      });

      const collator = new Intl.Collator('en');
      const data = produce(sourceData, (draftData) => {
        const { nodes } = draftData.workspace.labels;
        nodes.push(label);
        nodes.sort((a, b) => collator.compare(a.title, b.title));
      });

      store.writeQuery({
        query,
        variables: { fullPath: this.fullPath, searchTerm: '' },
        data,
      });
    },
    async createLabel() {
      this.labelCreateInProgress = true;
      try {
        const {
          data: { labelCreate },
        } = await this.$apollo.mutate({
          mutation: createLabelMutation,
          variables: this.mutationVariables,
          update: (
            store,
            {
              data: {
                labelCreate: { label },
              },
            },
          ) => {
            if (label) {
              this.updateLabelsInCache(store, label);
            }
          },
        });
        if (labelCreate.errors.length) {
          [this.error] = labelCreate.errors;
        } else {
          this.$emit('labelCreated', labelCreate.label);
        }
      } catch {
        createAlert({ message: errorMessage });
      }
      this.labelCreateInProgress = false;
    },
  },
};
</script>

<template>
  <div class="labels-select-contents-create js-labels-create">
    <div class="dropdown-input">
      <gl-alert v-if="error" variant="danger" :dismissible="false" class="gl-mt-3">
        {{ error }}
      </gl-alert>
      <gl-form-input
        v-model.trim="labelTitle"
        class="gl-mt-3"
        :placeholder="__('Name new label')"
        :autofocus="true"
        data-testid="label-title-input"
      />
    </div>
    <div class="dropdown-content gl-px-3">
      <div class="suggest-colors suggest-colors-dropdown gl-mt-0! gl-mb-3! gl-mb-0">
        <gl-link
          v-for="(color, index) in suggestedColors"
          :key="index"
          v-gl-tooltip:tooltipcontainer
          :style="{ backgroundColor: getColorCode(color) }"
          :title="getColorName(color)"
          @click.prevent="handleColorClick(color)"
        />
      </div>
      <div class="color-input-container gl-display-flex">
        <gl-form-input
          v-model.trim="selectedColor"
          class="gl-rounded-top-right-none gl-rounded-bottom-right-none gl-mr-n1 gl-mb-2 gl-w-8"
          type="color"
          :value="selectedColor"
          :placeholder="__('Select color')"
          data-testid="selected-color"
        />
        <gl-form-input
          v-model.trim="selectedColor"
          class="gl-rounded-top-left-none gl-rounded-bottom-left-none gl-mb-2"
          :placeholder="__('Use custom color #FF0000')"
          data-testid="selected-color-text"
        />
      </div>
    </div>
    <div class="dropdown-actions gl-display-flex gl-justify-content-space-between gl-pt-3 gl-px-3">
      <gl-button
        :disabled="disableCreate"
        category="primary"
        variant="confirm"
        class="gl-display-flex gl-align-items-center"
        data-testid="create-button"
        @click="createLabel"
      >
        <gl-loading-icon v-if="labelCreateInProgress" size="sm" :inline="true" class="mr-1" />
        {{ __('Create') }}
      </gl-button>
      <gl-button
        class="js-btn-cancel-create"
        data-testid="cancel-button"
        @click.stop="$emit('hideCreateView')"
      >
        {{ __('Cancel') }}
      </gl-button>
    </div>
  </div>
</template>

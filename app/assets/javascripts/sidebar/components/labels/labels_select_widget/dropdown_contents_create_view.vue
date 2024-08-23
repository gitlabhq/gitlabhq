<script>
import { get } from 'lodash';
import { GlAlert, GlTooltipDirective, GlButton, GlFormGroup, GlFormInput } from '@gitlab/ui';
import produce from 'immer';
import { createAlert } from '~/alert';
import { WORKSPACE_GROUP } from '~/issues/constants';
import { __ } from '~/locale';
import SidebarColorPicker from '../../sidebar_color_picker.vue';
import { workspaceLabelsQueries, workspaceCreateLabelMutation } from '../../../queries/constants';
import { DEFAULT_LABEL_COLOR } from './constants';

const errorMessage = __('Error creating label.');

export default {
  components: {
    GlAlert,
    GlButton,
    GlFormGroup,
    GlFormInput,
    SidebarColorPicker,
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
      const variables = {
        title: this.labelTitle,
        color: this.selectedColor,
      };

      if (this.labelCreateType) {
        const attributePath =
          this.labelCreateType === WORKSPACE_GROUP ? 'groupPath' : 'projectPath';

        return { ...variables, [attributePath]: this.attrWorkspacePath };
      }

      return variables;
    },
  },
  methods: {
    updateLabelsInCache(store, label) {
      const { query, dataPath } = workspaceLabelsQueries[this.workspaceType];

      const sourceData = store.readQuery({
        query,
        variables: { fullPath: this.fullPath, searchTerm: '' },
      });

      const collator = new Intl.Collator('en');
      const data = produce(sourceData, (draftData) => {
        const { nodes } = get(draftData, dataPath);
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
          mutation: workspaceCreateLabelMutation[this.workspaceType],
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
  <div class="gl-px-4">
    <gl-alert v-if="error" variant="danger" :dismissible="false" class="gl-mt-3">
      {{ error }}
    </gl-alert>
    <gl-form-group
      class="gl-my-3"
      :label="__('Label name')"
      label-for="label-title-input"
      label-sr-only
    >
      <gl-form-input
        id="label-title-input"
        v-model.trim="labelTitle"
        autofocus
        :placeholder="__('Label name')"
      />
    </gl-form-group>
    <sidebar-color-picker v-model.trim="selectedColor" :suggested-colors="suggestedColors" />
    <div class="gl-mt-2 gl-flex gl-justify-end gl-gap-3">
      <gl-button
        class="js-btn-cancel-create"
        size="small"
        data-testid="cancel-button"
        @click.stop="$emit('hideCreateView')"
      >
        {{ __('Cancel') }}
      </gl-button>
      <gl-button
        :disabled="disableCreate"
        :loading="labelCreateInProgress"
        size="small"
        variant="confirm"
        data-testid="create-button"
        @click="createLabel"
      >
        {{ __('Create') }}
      </gl-button>
    </div>
  </div>
</template>

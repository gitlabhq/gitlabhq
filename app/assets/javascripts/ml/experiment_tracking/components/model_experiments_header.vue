<script>
import {
  GlBadge,
  GlDisclosureDropdown,
  GlDisclosureDropdownGroup,
  GlDisclosureDropdownItem,
  GlModalDirective,
} from '@gitlab/ui';
import { __, s__ } from '~/locale';
import { helpPagePath } from '~/helpers/help_page_helper';
import TitleArea from '~/vue_shared/components/registry/title_area.vue';
import { MLFLOW_USAGE_MODAL_ID } from '../routes/experiments/index/constants';
import MlflowModal from '../routes/experiments/index/components/mlflow_usage_modal.vue';

export default {
  components: {
    GlBadge,
    GlDisclosureDropdown,
    GlDisclosureDropdownGroup,
    GlDisclosureDropdownItem,
    MlflowModal,
    TitleArea,
  },
  directives: {
    GlModal: GlModalDirective,
  },
  props: {
    pageTitle: {
      type: String,
      required: true,
    },
    hideMlflowUsage: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  computed: {
    mlflowUsageModalItem() {
      return {
        text: this.$options.i18n.importMlflow,
      };
    },
  },
  i18n: {
    experimentBadgeLabel: __('Experiment'),
    createTitle: s__('MlModelRegistry|Create'),
    importMlflow: s__('MlModelRegistry|Create experiments using MLflow'),
  },
  experimentDocHref: helpPagePath('user/project/ml/experiment_tracking/index.md'),
  mlflowModalId: MLFLOW_USAGE_MODAL_ID,
};
</script>

<template>
  <title-area>
    <template #title>
      <div class="gl-flex gl-grow gl-items-center">
        <span class="gl-inline-flex gl-items-center gl-gap-3" data-testid="page-heading">
          {{ pageTitle }}
          <gl-badge variant="info" :href="$options.experimentDocHref">
            {{ $options.i18n.experimentBadgeLabel }}
          </gl-badge>
          <slot></slot>
        </span>
      </div>
    </template>
    <template #right-actions>
      <gl-disclosure-dropdown
        v-if="!hideMlflowUsage"
        :toggle-text="$options.i18n.createTitle"
        toggle-class="gl-w-full"
        data-testid="create-dropdown"
        variant="confirm"
        category="primary"
        placement="bottom-end"
      >
        <gl-disclosure-dropdown-group>
          <gl-disclosure-dropdown-item
            v-gl-modal="$options.mlflowModalId"
            data-testid="create-menu-item"
            :item="mlflowUsageModalItem"
          />
        </gl-disclosure-dropdown-group>
        <mlflow-modal />
      </gl-disclosure-dropdown>
    </template>
  </title-area>
</template>

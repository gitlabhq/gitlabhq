<script>
import {
  GlBadge,
  GlButton,
  GlButtonGroup,
  GlTooltipDirective,
  GlModal,
  GlToggle,
  GlTableLite,
} from '@gitlab/ui';
import { __, s__, sprintf } from '~/locale';
import { labelForStrategy } from '../utils';

import StrategyLabel from './strategy_label.vue';

export default {
  i18n: {
    deleteLabel: __('Delete'),
    editLabel: __('Edit'),
    toggleLabel: __('Feature flag status'),
  },
  components: {
    GlBadge,
    GlButton,
    GlButtonGroup,
    GlModal,
    GlToggle,
    GlTableLite,
    StrategyLabel,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  inject: ['csrfToken'],
  props: {
    featureFlags: {
      type: Array,
      required: true,
    },
  },
  data() {
    return {
      deleteFeatureFlagUrl: null,
      deleteFeatureFlagName: null,
    };
  },
  computed: {
    tableFields() {
      return [
        {
          key: 'id',
          label: s__('FeatureFlags|ID'),
        },
        {
          key: 'status',
          label: s__('FeatureFlags|Status'),
        },
        {
          key: 'name',
          label: s__('FeatureFlags|Feature flag'),
        },
        {
          key: 'env_specs',
          label: s__('FeatureFlags|Environment Specs'),
          thClass: 'gl-w-1/2',
        },
        {
          key: 'actions',
          label: __('Actions'),
          thClass: 'gl-w-1/12',
        },
      ];
    },
    modalTitle() {
      return sprintf(s__('FeatureFlags|Delete %{name}?'), {
        name: this.deleteFeatureFlagName,
      });
    },
    deleteModalMessage() {
      return sprintf(s__('FeatureFlags|Feature flag %{name} will be removed. Are you sure?'), {
        name: this.deleteFeatureFlagName,
      });
    },
    modalId() {
      return 'delete-feature-flag';
    },
  },
  methods: {
    scopeTooltipText(scope) {
      return !scope.active
        ? sprintf(s__('FeatureFlags|Inactive flag for %{scope}'), {
            scope: scope.environmentScope,
          })
        : '';
    },
    strategyBadgeText(strategy) {
      return labelForStrategy(strategy);
    },
    featureFlagIidText(featureFlag) {
      return featureFlag.iid ? `^${featureFlag.iid}` : '';
    },
    canDeleteFlag(flag) {
      return (flag.scopes || []).every((scope) => scope.can_update);
    },
    setDeleteModalData(featureFlag) {
      this.deleteFeatureFlagUrl = featureFlag.destroy_path;
      this.deleteFeatureFlagName = featureFlag.name;

      this.$refs[this.modalId].show();
    },
    onSubmit() {
      this.$refs.form.submit();
    },
    toggleFeatureFlag(flag) {
      this.$emit('toggle-flag', {
        ...flag,
        active: !flag.active,
      });
    },
  },
  modal: {
    actionPrimary: {
      text: s__('FeatureFlags|Delete feature flag'),
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
};
</script>
<template>
  <div>
    <gl-table-lite :fields="tableFields" :items="featureFlags" stacked="md">
      <template #cell(id)="{ item = {} }">
        <div class="!gl-text-left" data-testid="feature-flag-id">
          {{ featureFlagIidText(item) }}
        </div>
      </template>

      <template #cell(status)="{ item = {} }">
        <gl-toggle
          v-if="item.update_path"
          :value="item.active"
          :label="$options.i18n.toggleLabel"
          label-position="hidden"
          data-testid="feature-flag-status-toggle"
          data-track-action="click_button"
          data-track-label="feature_flag_toggle"
          @change="toggleFeatureFlag(item)"
        />
        <gl-badge
          v-else-if="item.active"
          variant="success"
          data-testid="feature-flag-status-badge"
          >{{ s__('FeatureFlags|Active') }}</gl-badge
        >
        <gl-badge v-else variant="danger">{{ s__('FeatureFlags|Inactive') }}</gl-badge>
      </template>

      <template #cell(name)="{ item = {} }">
        <div class="gl-flex" data-testid="feature-flag-title">
          <div class="gl-flex gl-items-center">
            <div class="feature-flag-name text-monospace text-wrap gl-break-anywhere">
              {{ item.name }}
            </div>
            <div :data-testid="`feature-flag-description-${item.id}`">
              <gl-button
                v-if="item.description"
                v-gl-tooltip.hover="item.description"
                :aria-label="item.description"
                class="gl-mx-3 !gl-p-0"
                category="tertiary"
                size="small"
                icon="information-o"
              />
            </div>
          </div>
        </div>
      </template>

      <template #cell(env_specs)="{ item = {} }">
        <div class="gl-flex gl-flex-wrap" data-testid="feature-flag-environments">
          <strategy-label
            v-for="strategy in item.strategies"
            :key="strategy.id"
            data-testid="strategy-label"
            class="gl-mr-3 gl-mt-2 gl-w-full gl-whitespace-normal !gl-text-left"
            v-bind="strategyBadgeText(strategy)"
          />
        </div>
      </template>

      <template #cell(actions)="{ item = {} }">
        <gl-button-group
          class="gl-hidden md:gl-inline-flex"
          data-testid="flags-table-action-buttons"
        >
          <template v-if="item.edit_path">
            <gl-button
              v-gl-tooltip.hover.bottom="$options.i18n.editLabel"
              data-testid="feature-flag-edit-button"
              class="gl-flex-grow"
              icon="pencil"
              :aria-label="$options.i18n.editLabel"
              :href="item.edit_path"
            />
          </template>
          <template v-if="item.destroy_path">
            <gl-button
              v-gl-tooltip.hover.bottom="$options.i18n.deleteLabel"
              class="gl-flex-grow"
              variant="danger"
              icon="remove"
              :disabled="!canDeleteFlag(item)"
              :aria-label="$options.i18n.deleteLabel"
              @click="setDeleteModalData(item)"
            />
          </template>
        </gl-button-group>

        <div
          class="gl-flex gl-gap-4 md:gl-hidden md:gl-gap-0"
          data-testid="flags-table-action-buttons"
        >
          <template v-if="item.edit_path">
            <gl-button
              v-gl-tooltip.hover.bottom="$options.i18n.editLabel"
              data-testid="feature-flag-edit-button"
              class="gl-flex-grow"
              icon="pencil"
              :aria-label="$options.i18n.editLabel"
              :href="item.edit_path"
            />
          </template>
          <template v-if="item.destroy_path">
            <gl-button
              v-gl-tooltip.hover.bottom="$options.i18n.deleteLabel"
              data-testid="feature-flag-delete-button"
              class="gl-flex-grow"
              variant="danger"
              icon="remove"
              :disabled="!canDeleteFlag(item)"
              :aria-label="$options.i18n.deleteLabel"
              @click="setDeleteModalData(item)"
            />
          </template>
        </div>
      </template>
    </gl-table-lite>

    <gl-modal
      :ref="modalId"
      :title="modalTitle"
      :modal-id="modalId"
      title-tag="h4"
      size="sm"
      :action-primary="$options.modal.actionPrimary"
      :action-secondary="$options.modal.actionSecondary"
      @ok="onSubmit"
    >
      {{ deleteModalMessage }}
      <form ref="form" :action="deleteFeatureFlagUrl" method="post">
        <input ref="method" type="hidden" name="_method" value="delete" />
        <input :value="csrfToken" type="hidden" name="authenticity_token" />
      </form>
    </gl-modal>
  </div>
</template>

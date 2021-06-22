<script>
import { GlBadge, GlButton, GlTooltipDirective, GlModal, GlToggle } from '@gitlab/ui';
import { __, s__, sprintf } from '~/locale';
import glFeatureFlagMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { labelForStrategy } from '../utils';

export default {
  i18n: {
    deleteLabel: __('Delete'),
    editLabel: __('Edit'),
    toggleLabel: __('Feature flag status'),
  },
  components: {
    GlBadge,
    GlButton,
    GlModal,
    GlToggle,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  mixins: [glFeatureFlagMixin()],
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
      return !this.permissions || (flag.scopes || []).every((scope) => scope.can_update);
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
};
</script>
<template>
  <div class="table-holder js-feature-flag-table">
    <div class="gl-responsive-table-row table-row-header" role="row">
      <div class="table-section section-10">{{ s__('FeatureFlags|ID') }}</div>
      <div class="table-section section-10" role="columnheader">
        {{ s__('FeatureFlags|Status') }}
      </div>
      <div class="table-section section-20" role="columnheader">
        {{ s__('FeatureFlags|Feature Flag') }}
      </div>
      <div class="table-section section-40" role="columnheader">
        {{ s__('FeatureFlags|Environment Specs') }}
      </div>
    </div>

    <template v-for="featureFlag in featureFlags">
      <div :key="featureFlag.id" class="gl-responsive-table-row" role="row">
        <div class="table-section section-10" role="gridcell">
          <div class="table-mobile-header" role="rowheader">{{ s__('FeatureFlags|ID') }}</div>
          <div class="table-mobile-content js-feature-flag-id">
            {{ featureFlagIidText(featureFlag) }}
          </div>
        </div>
        <div class="table-section section-10" role="gridcell">
          <div class="table-mobile-header" role="rowheader">{{ s__('FeatureFlags|Status') }}</div>
          <div class="table-mobile-content">
            <gl-toggle
              v-if="featureFlag.update_path"
              :value="featureFlag.active"
              :label="$options.i18n.toggleLabel"
              label-position="hidden"
              data-testid="feature-flag-status-toggle"
              data-track-event="click_button"
              data-track-label="feature_flag_toggle"
              @change="toggleFeatureFlag(featureFlag)"
            />
            <gl-badge
              v-else-if="featureFlag.active"
              variant="success"
              data-testid="feature-flag-status-badge"
              >{{ s__('FeatureFlags|Active') }}</gl-badge
            >
            <gl-badge v-else variant="danger">{{ s__('FeatureFlags|Inactive') }}</gl-badge>
          </div>
        </div>

        <div class="table-section section-20" role="gridcell">
          <div class="table-mobile-header" role="rowheader">
            {{ s__('FeatureFlags|Feature Flag') }}
          </div>
          <div class="table-mobile-content d-flex flex-column js-feature-flag-title">
            <div class="gl-display-flex gl-align-items-center">
              <div class="feature-flag-name text-monospace text-truncate">
                {{ featureFlag.name }}
              </div>
            </div>
            <div class="feature-flag-description text-secondary text-truncate">
              {{ featureFlag.description }}
            </div>
          </div>
        </div>

        <div class="table-section section-40" role="gridcell">
          <div class="table-mobile-header" role="rowheader">
            {{ s__('FeatureFlags|Environment Specs') }}
          </div>
          <div
            class="table-mobile-content d-flex flex-wrap justify-content-end justify-content-md-start js-feature-flag-environments"
          >
            <gl-badge
              v-for="strategy in featureFlag.strategies"
              :key="strategy.id"
              data-testid="strategy-badge"
              variant="info"
              class="gl-mr-3 gl-mt-2 gl-white-space-normal gl-text-left gl-px-5"
              >{{ strategyBadgeText(strategy) }}</gl-badge
            >
          </div>
        </div>

        <div class="table-section section-20 table-button-footer" role="gridcell">
          <div class="table-action-buttons btn-group">
            <template v-if="featureFlag.edit_path">
              <gl-button
                v-gl-tooltip.hover.bottom="$options.i18n.editLabel"
                class="js-feature-flag-edit-button"
                icon="pencil"
                :aria-label="$options.i18n.editLabel"
                :href="featureFlag.edit_path"
              />
            </template>
            <template v-if="featureFlag.destroy_path">
              <gl-button
                v-gl-tooltip.hover.bottom="$options.i18n.deleteLabel"
                class="js-feature-flag-delete-button"
                variant="danger"
                icon="remove"
                :disabled="!canDeleteFlag(featureFlag)"
                :aria-label="$options.i18n.deleteLabel"
                @click="setDeleteModalData(featureFlag)"
              />
            </template>
          </div>
        </div>
      </div>
    </template>

    <gl-modal
      :ref="modalId"
      :title="modalTitle"
      :ok-title="s__('FeatureFlags|Delete feature flag')"
      :modal-id="modalId"
      title-tag="h4"
      ok-variant="danger"
      category="primary"
      @ok="onSubmit"
    >
      {{ deleteModalMessage }}
      <form ref="form" :action="deleteFeatureFlagUrl" method="post" class="js-requires-input">
        <input ref="method" type="hidden" name="_method" value="delete" />
        <input :value="csrfToken" type="hidden" name="authenticity_token" />
      </form>
    </gl-modal>
  </div>
</template>

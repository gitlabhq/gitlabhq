<script>
import { GlButton, GlFormInput, GlFormGroup, GlIcon, GlExperimentBadge } from '@gitlab/ui';
import { isEqual } from 'lodash';
import { createAlert } from '~/alert';
import { cloneWithoutReferences } from '~/lib/utils/common_utils';
import { slugify } from '~/lib/utils/text_utility';
import { s__, __ } from '~/locale';
import { InternalEvents } from '~/tracking';
import glFeatureFlagsMixin from '~/vue_shared/mixins/gl_feature_flags_mixin';
import { confirmAction } from '~/lib/utils/confirm_via_gl_modal/confirm_via_gl_modal';
import { EVENT_LABEL_VIEWED_DASHBOARD_DESIGNER, DASHBOARD_STATUS_BETA } from './constants';
import GridstackWrapper from './gridstack_wrapper.vue';
import AvailableVisualizationsDrawer from './dashboard_editor/available_visualizations_drawer.vue';
import {
  getDashboardConfig,
  availableVisualizationsValidator,
  createNewVisualizationPanel,
} from './utils';

export default {
  name: 'CustomizableDashboard',
  components: {
    GlButton,
    GlFormInput,
    GlIcon,
    GlFormGroup,
    GlExperimentBadge,
    AvailableVisualizationsDrawer,
    GridstackWrapper,
  },
  mixins: [InternalEvents.mixin(), glFeatureFlagsMixin()],
  props: {
    initialDashboard: {
      type: Object,
      required: true,
      default: () => {},
    },
    availableVisualizations: {
      type: Object,
      required: false,
      default: () => {},
      validator: availableVisualizationsValidator,
    },
    isSaving: {
      type: Boolean,
      required: false,
      default: false,
    },
    changesSaved: {
      type: Boolean,
      required: false,
      default: false,
    },
    isNewDashboard: {
      type: Boolean,
      required: false,
      default: false,
    },
    titleValidationError: {
      type: String,
      required: false,
      default: null,
    },
    editingEnabled: {
      type: Boolean,
      required: false,
      default: true,
    },
  },
  data() {
    return {
      dashboard: this.createDraftDashboard(this.initialDashboard),
      editing: this.isNewDashboard,
      alert: null,
      visualizationDrawerOpen: false,
    };
  },
  computed: {
    showFilters() {
      return !this.editing && this.$scopedSlots.filters;
    },
    showEditControls() {
      return this.editingEnabled && this.editing;
    },
    showDashboardDescription() {
      return Boolean(this.dashboard.description) && !this.editing;
    },
    showEditDashboardButton() {
      return this.editingEnabled && !this.editing;
    },
    showBetaBadge() {
      return this.dashboard.status === DASHBOARD_STATUS_BETA;
    },
    dashboardDescription() {
      return this.dashboard.description;
    },
    changesMade() {
      // Compare the dashboard configs as that is what will be saved
      return !isEqual(
        getDashboardConfig(this.initialDashboard),
        getDashboardConfig(this.dashboard),
      );
    },
  },
  watch: {
    isNewDashboard(isNew) {
      this.editing = isNew;
    },
    changesSaved: {
      handler(saved) {
        if (saved && this.editing) {
          this.editing = false;
        }
      },
      immediate: true,
    },
    '$route.params.editing': {
      handler(editing) {
        if (editing !== undefined) {
          this.editing = editing;
        }
      },
      immediate: true,
    },
    editing: {
      handler(editing) {
        this.grid?.setStatic(!editing);
        if (!editing) {
          this.closeVisualizationDrawer();
        } else {
          this.trackEvent(EVENT_LABEL_VIEWED_DASHBOARD_DESIGNER);
        }
      },
      immediate: true,
    },
    initialDashboard() {
      this.resetToInitialDashboard();
    },
  },
  mounted() {
    const wrappers = document.querySelectorAll('.container-fluid.container-limited');

    wrappers.forEach((el) => {
      el.classList.add('not-container-limited');
      el.classList.remove('container-limited');
    });

    window.addEventListener('beforeunload', this.onPageUnload);
  },
  beforeDestroy() {
    const wrappers = document.querySelectorAll('.container-fluid.not-container-limited');

    wrappers.forEach((el) => {
      el.classList.add('container-limited');
      el.classList.remove('not-container-limited');
    });

    this.alert?.dismiss();

    window.removeEventListener('beforeunload', this.onPageUnload);
  },
  methods: {
    onPageUnload(event) {
      if (!this.changesMade) return undefined;

      event.preventDefault();
      // This returnValue is required on some browsers. This message is displayed on older versions.
      // https://developer.mozilla.org/en-US/docs/Web/API/Window/beforeunload_event#compatibility_notes
      const returnValue = __('Are you sure you want to lose unsaved changes?');
      Object.assign(event, { returnValue });
      return returnValue;
    },
    createDraftDashboard(dashboard) {
      return cloneWithoutReferences(dashboard);
    },
    resetToInitialDashboard() {
      this.dashboard = this.createDraftDashboard(this.initialDashboard);
    },
    onTitleInput(submitting) {
      this.$emit('title-input', this.dashboard.title, submitting);
    },
    startEdit() {
      this.editing = true;
    },
    async saveEdit() {
      if (this.titleValidationError === null && this.isNewDashboard) {
        // ensure validation gets run when form is submitted with an empty title
        this.onTitleInput(true);
        this.$refs.titleInput.$el.focus();
        return;
      }

      if (this.titleValidationError) {
        this.$refs.titleInput.$el.focus();
        return;
      }

      if (this.isNewDashboard && this.dashboard.panels.length < 1) {
        this.alert = createAlert({
          message: s__('Analytics|Add a visualization'),
        });
        return;
      }

      this.alert?.dismiss();

      if (this.isNewDashboard) {
        this.dashboard.slug = slugify(this.dashboard.title, '_');
      }

      this.$emit('save', this.dashboard.slug, this.dashboard);
    },
    async confirmDiscardIfChanged() {
      // Implicityly confirm if no changes were made
      if (!this.changesMade) return true;

      // No need to confirm while saving
      if (this.isSaving) return true;

      return this.confirmDiscardChanges();
    },
    async cancelEdit() {
      if (this.changesMade) {
        const confirmed = await this.confirmDiscardChanges();

        if (!confirmed) return;

        this.resetToInitialDashboard();
      }

      if (this.isNewDashboard) {
        this.$router.push('/');
        return;
      }

      this.editing = false;
    },
    async confirmDiscardChanges() {
      const confirmText = this.isNewDashboard
        ? s__('Analytics|Are you sure you want to cancel creating this dashboard?')
        : s__('Analytics|Are you sure you want to cancel editing this dashboard?');

      const cancelBtnText = this.isNewDashboard
        ? s__('Analytics|Continue creating')
        : s__('Analytics|Continue editing');

      return confirmAction(confirmText, {
        primaryBtnText: __('Discard changes'),
        cancelBtnText,
      });
    },

    toggleVisualizationDrawer() {
      this.visualizationDrawerOpen = !this.visualizationDrawerOpen;
    },
    closeVisualizationDrawer() {
      this.visualizationDrawerOpen = false;
    },
    deletePanel(panel) {
      const removeIndex = this.dashboard.panels.findIndex((p) => p.id === panel.id);
      this.dashboard.panels.splice(removeIndex, 1);
    },
    addPanels(visualizations) {
      this.closeVisualizationDrawer();

      const panels = visualizations.map((viz) => createNewVisualizationPanel(viz));
      this.dashboard.panels.push(...panels);
    },
  },
  FORM_GROUP_CLASS: 'gl-w-full sm:gl-w-3/10 gl-min-w-20 gl-m-0',
  FORM_INPUT_CLASS: 'form-control gl-mr-4 gl-border-strong',
};
</script>

<template>
  <div>
    <section class="gl-my-4 gl-flex gl-items-center">
      <div class="gl-flex gl-w-full gl-flex-col">
        <h2 v-if="showEditControls" data-testid="edit-mode-title" class="gl-mb-6 gl-mt-0">
          {{
            isNewDashboard
              ? s__('Analytics|Create your dashboard')
              : s__('Analytics|Edit your dashboard')
          }}
        </h2>
        <div v-else class="gl-flex gl-items-center">
          <h2 data-testid="dashboard-title" class="gl-my-0">{{ dashboard.title }}</h2>
          <gl-experiment-badge v-if="showBetaBadge" class="gl-ml-3" type="beta" />
        </div>

        <div
          v-if="showDashboardDescription"
          class="gl-mt-3 gl-flex"
          data-testid="dashboard-description"
        >
          <p class="gl-mb-0">
            {{ dashboardDescription }}
            <slot name="after-description"></slot>
          </p>
        </div>

        <div v-if="showEditControls" class="flex-fill gl-flex gl-flex-col">
          <gl-form-group
            :label="s__('Analytics|Dashboard title')"
            label-for="title"
            :class="$options.FORM_GROUP_CLASS"
            class="gl-mb-4"
            data-testid="dashboard-title-form-group"
            :invalid-feedback="titleValidationError"
            :state="!titleValidationError"
          >
            <gl-form-input
              id="title"
              ref="titleInput"
              v-model="dashboard.title"
              dir="auto"
              type="text"
              :placeholder="s__('Analytics|Enter a dashboard title')"
              :aria-label="s__('Analytics|Dashboard title')"
              :class="$options.FORM_INPUT_CLASS"
              data-testid="dashboard-title-input"
              :state="!titleValidationError"
              required
              @input="onTitleInput"
            />
          </gl-form-group>
          <gl-form-group
            :label="s__('Analytics|Dashboard description (optional)')"
            label-for="description"
            :class="$options.FORM_GROUP_CLASS"
          >
            <gl-form-input
              id="description"
              v-model="dashboard.description"
              dir="auto"
              type="text"
              :placeholder="s__('Analytics|Enter a dashboard description')"
              :aria-label="s__('Analytics|Dashboard description')"
              :class="$options.FORM_INPUT_CLASS"
              data-testid="dashboard-description-input"
            />
          </gl-form-group>
        </div>
      </div>

      <gl-button
        v-if="showEditDashboardButton"
        icon="pencil"
        class="gl-mr-2"
        data-testid="dashboard-edit-btn"
        @click="startEdit"
        >{{ s__('Analytics|Edit') }}</gl-button
      >
    </section>
    <div class="-gl-mx-3">
      <div class="gl-flex">
        <div class="gl-flex gl-grow gl-flex-col">
          <section
            v-if="showFilters"
            data-testid="dashboard-filters"
            class="gl-flex gl-flex-col gl-gap-5 gl-px-3 gl-pb-3 gl-pt-4 md:gl-flex-row"
          >
            <slot name="filters"></slot>
          </section>

          <button
            v-if="showEditControls"
            class="card upload-dropzone-card upload-dropzone-border gl-m-3 gl-flex gl-items-center gl-px-5 gl-py-3"
            data-testid="add-visualization-button"
            @click="toggleVisualizationDrawer"
          >
            <div class="gl-flex gl-items-center gl-font-bold gl-text-subtle">
              <div
                class="gl-mr-3 gl-inline-flex gl-h-7 gl-w-7 gl-items-center gl-justify-center gl-rounded-full gl-bg-gray-100"
              >
                <gl-icon name="plus" />
              </div>
              {{ s__('Analytics|Add visualization') }}
            </div>
          </button>
          <slot name="alert"></slot>
          <gridstack-wrapper v-model="dashboard" :editing="editing">
            <template #panel="{ panel }">
              <slot
                name="panel"
                v-bind="{ panel, editing, deletePanel: () => deletePanel(panel) }"
              ></slot>
            </template>
          </gridstack-wrapper>

          <available-visualizations-drawer
            :visualizations="availableVisualizations.visualizations"
            :loading="availableVisualizations.loading"
            :has-error="availableVisualizations.hasError"
            :open="visualizationDrawerOpen"
            @select="addPanels"
            @close="closeVisualizationDrawer"
          />
        </div>
      </div>
    </div>
    <template v-if="editing">
      <gl-button
        :loading="isSaving"
        class="gl-my-4 gl-mr-2"
        category="primary"
        variant="confirm"
        data-testid="dashboard-save-btn"
        @click="saveEdit"
        >{{ s__('Analytics|Save your dashboard') }}</gl-button
      >
      <gl-button category="secondary" data-testid="dashboard-cancel-edit-btn" @click="cancelEdit">{{
        s__('Analytics|Cancel')
      }}</gl-button>
    </template>
  </div>
</template>

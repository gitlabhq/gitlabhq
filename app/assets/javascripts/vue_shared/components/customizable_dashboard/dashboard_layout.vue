<script>
import GridstackWrapper from './gridstack_wrapper.vue';
import dashboardConfigValidator from './utils';

export default {
  name: 'DashboardLayout',
  components: {
    GridstackWrapper,
  },
  props: {
    /**
     * The dashboard configuration object.
     *
     * @typedef {Object} Dashboard
     * @property {Object} title - The dashboard title to render. Expected if no #title slot is provided.
     * @property {Object} description - Optional: The dashboard description to render.
     * @property {Array<Object>} panels - Optional: The dashboard panels. The entire object is passed to the #panel slot.
     * @property {string} panels[].id - Each panel must have a unique ID.
     * @property {string} panels[].title - The panel title to render.
     * @property {Object} panels[].gridAttributes - Layout settings for the panel.
     * @property {number} panels[].gridAttributes.width - Width of the panel in grid units.
     * @property {number} panels[].gridAttributes.height - Height of the panel in grid units.
     * @property {number} panels[].gridAttributes.xPos - X position of the panel in the grid, expressed in grid units, starts from 0.
     * @property {number} panels[].gridAttributes.yPos - Y position of the panel in the grid, expressed in grid units, starts from 0.
     *
     * @type {Dashboard}
     */
    config: {
      type: Object,
      required: true,
      validator: dashboardConfigValidator,
    },
  },
  computed: {
    dashboardHasPanels() {
      return this.config.panels?.length > 0;
    },
    dashboardHasDescription() {
      return this.$scopedSlots.description || Boolean(this.config.description);
    },
  },
};
</script>
<template>
  <div>
    <section class="gl-my-4 gl-flex gl-items-center">
      <div class="gl-flex gl-w-full gl-flex-col">
        <!-- Dashboard title -->
        <div class="gl-flex gl-items-center">
          <!-- @slot Used to render custom dashboard titles. Replaces the default rendering. -->
          <slot name="title">
            <h2 data-testid="title" class="gl-my-0">{{ config.title }}</h2>
          </slot>
        </div>
        <!-- Dashboard description -->
        <div v-if="dashboardHasDescription" class="gl-mt-3 gl-flex">
          <!-- @slot Used to render custom dashboard descriptions. Replaces the default rendering. -->
          <slot name="description">
            <p data-testid="description" class="gl-mb-0">
              {{ config.description }}
            </p>
          </slot>
        </div>
      </div>
      <div v-if="$scopedSlots.actions" data-testid="actions-container">
        <!-- @slot Place dashboard actions inside this slot. -->
        <slot name="actions"></slot>
      </div>
    </section>
    <div class="gl-flex">
      <div class="gl-flex gl-grow gl-flex-col">
        <!-- @slot For dashboard-level alerts. -->
        <slot name="alert"></slot>

        <!-- Dashboard filters -->
        <section
          v-if="$scopedSlots.filters"
          class="gl-flex gl-flex-row gl-flex-wrap gl-gap-5 gl-pb-3 gl-pt-4"
          data-testid="filters-container"
        >
          <!-- @slot Place dashboard filters inside this slot. -->
          <slot name="filters"></slot>
        </section>

        <!-- Dashboard grid -->
        <gridstack-wrapper v-if="dashboardHasPanels" :value="config" class="-gl-mx-3">
          <template #panel="{ panel }">
            <!-- @slot The contents to render inside each dashboard panel. -->
            <slot name="panel" v-bind="{ panel }"></slot>
          </template>
        </gridstack-wrapper>

        <!-- @slot Shown when a dashboard has no panels. -->
        <slot v-else name="empty-state"></slot>
      </div>
    </div>
    <!-- @slot Optional: The dashboard footer content. -->
    <slot name="footer"></slot>
  </div>
</template>

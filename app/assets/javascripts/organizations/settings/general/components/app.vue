<script>
import SearchSettings from '~/search_settings/components/search_settings.vue';
import OrganizationSettings from './organization_settings.vue';
import VisibilityLevel from './visibility_level.vue';
import AdvancedSettings from './advanced_settings.vue';

const ORGANIZATION_SETTINGS_ID = 'organization-settings';
const VISIBILITY_LEVEL_ID = 'organization-settings-visibility';
const ADVANCED_SETTINGS_ID = 'organization-settings-advanced';

export default {
  name: 'OrganizationSettingsGeneralApp',
  components: { SearchSettings, OrganizationSettings, VisibilityLevel, AdvancedSettings },
  ORGANIZATION_SETTINGS_ID,
  VISIBILITY_LEVEL_ID,
  ADVANCED_SETTINGS_ID,
  data() {
    return {
      sectionsExpandedState: {
        [ORGANIZATION_SETTINGS_ID]: true,
        [VISIBILITY_LEVEL_ID]: false,
        [ADVANCED_SETTINGS_ID]: false,
      },
      searchRoot: null,
    };
  },
  mounted() {
    this.searchRoot = this.$refs.searchRoot;
  },
  methods: {
    isExpanded(section) {
      const sectionId = section.getAttribute('id');

      return this.expandedProp(sectionId);
    },
    setSectionExpandedState(section, state) {
      const sectionId = section.getAttribute('id');

      this.setExpandedState(sectionId, state);
    },
    onSearchExpand(section) {
      this.setSectionExpandedState(section, true);
    },
    onSearchCollapse(section) {
      this.setSectionExpandedState(section, false);
    },
    onToggleExpand(sectionId, state) {
      this.setExpandedState(sectionId, state);
    },
    setExpandedState(sectionId, state) {
      // Reassigning keeps slot-injected EE sections reactive in Vue 2; their
      // ids are not pre-seeded in sectionsExpandedState.
      this.sectionsExpandedState = { ...this.sectionsExpandedState, [sectionId]: state };
    },
    expandedProp(sectionId) {
      return Boolean(this.sectionsExpandedState[sectionId]);
    },
  },
};
</script>

<template>
  <div class="gl-pt-5">
    <search-settings
      v-if="searchRoot"
      class="gl-mb-5"
      :search-root="searchRoot"
      section-selector=".vue-settings-block"
      :is-expanded-fn="isExpanded"
      @expand="onSearchExpand"
      @collapse="onSearchCollapse"
    />
    <div ref="searchRoot">
      <organization-settings
        :id="$options.ORGANIZATION_SETTINGS_ID"
        :expanded="expandedProp($options.ORGANIZATION_SETTINGS_ID)"
        @toggle-expand="onToggleExpand($options.ORGANIZATION_SETTINGS_ID, $event)"
      />
      <visibility-level
        :id="$options.VISIBILITY_LEVEL_ID"
        :expanded="expandedProp($options.VISIBILITY_LEVEL_ID)"
        @toggle-expand="onToggleExpand($options.VISIBILITY_LEVEL_ID, $event)"
      />
      <advanced-settings
        :id="$options.ADVANCED_SETTINGS_ID"
        :expanded="expandedProp($options.ADVANCED_SETTINGS_ID)"
        @toggle-expand="onToggleExpand($options.ADVANCED_SETTINGS_ID, $event)"
      />
      <!-- EE-only sections; inside searchRoot so search-settings indexes them. -->
      <slot
        name="ee-settings-sections"
        :expanded-prop="expandedProp"
        :on-toggle-expand="onToggleExpand"
      ></slot>
    </div>
  </div>
</template>

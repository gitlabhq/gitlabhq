<script>
import fuzzaldrinPlus from 'fuzzaldrin-plus';
import { GlDropdown, GlDropdownSectionHeader, GlDropdownItem, GlSearchBoxByType } from '@gitlab/ui';
import { __ } from '~/locale';

export default {
  components: {
    GlDropdown,
    GlDropdownSectionHeader,
    GlDropdownItem,
    GlSearchBoxByType,
  },
  props: {
    selectedTemplate: {
      type: String,
      required: false,
      default: '',
    },
    templates: {
      type: Array,
      required: true,
    },
    selectedFileTemplateProjectId: {
      type: Number,
      required: false,
      default: null,
    },
  },
  data() {
    return {
      searchTerm: '',
    };
  },
  computed: {
    templateOptions() {
      if (this.searchTerm) {
        const filteredTemplates = [];
        for (let i = 0; i < this.templates.length; i += 2) {
          const sectionName = this.templates[i];
          const availableTemplates = this.templates[i + 1];

          const matchedTemplates = fuzzaldrinPlus.filter(availableTemplates, this.searchTerm, {
            key: 'name',
          });

          if (matchedTemplates.length > 0) {
            filteredTemplates.push(sectionName, matchedTemplates);
          }
        }

        return filteredTemplates;
      }

      return this.templates;
    },
  },
  methods: {
    templateClick(template) {
      // Clicking on the same template should unselect it
      if (
        template.name === this.selectedTemplate &&
        template.project_id === this.selectedFileTemplateProjectId
      ) {
        this.$emit('change', {
          selectedFileTemplateProjectId: null,
          selectedTemplate: null,
        });
        return;
      }

      this.$emit('change', {
        selectedFileTemplateProjectId: template.project_id,
        selectedTemplate: template.key,
      });
    },
  },
  i18n: {
    defaultDropdownText: __('Choose a template'),
  },
};
</script>
<template>
  <gl-dropdown
    id="service-desk-template-select"
    :text="selectedTemplate || $options.i18n.defaultDropdownText"
    :header-text="$options.i18n.defaultDropdownText"
    :block="true"
    class="service-desk-template-select"
    toggle-class="gl-m-0"
  >
    <template #header>
      <gl-search-box-by-type v-model.trim="searchTerm" />
    </template>
    <template v-for="item in templateOptions">
      <gl-dropdown-section-header v-if="!Array.isArray(item)" :key="item">
        {{ item }}
      </gl-dropdown-section-header>
      <template v-else>
        <gl-dropdown-item
          v-for="template in item"
          :key="template.key"
          is-check-item
          :is-checked="
            template.project_id === selectedFileTemplateProjectId &&
            template.name === selectedTemplate
          "
          @click="() => templateClick(template)"
        >
          {{ template.name }}
        </gl-dropdown-item>
      </template>
    </template>
  </gl-dropdown>
</template>

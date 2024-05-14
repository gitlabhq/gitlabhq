<script>
import { GlCollapsibleListbox } from '@gitlab/ui';
import { __ } from '~/locale';
import { DEFAULT_CI_CONFIG_PATH, CI_CONFIG_PATH_EXTENSION } from '~/lib/utils/constants';

const templateSelectors = [
  {
    key: 'gitignore_names',
    name: '.gitignore',
    pattern: /(.gitignore)/,
    type: 'gitignores',
  },
  {
    key: 'gitlab_ci_ymls',
    name: DEFAULT_CI_CONFIG_PATH,
    pattern: CI_CONFIG_PATH_EXTENSION,
    type: 'gitlab_ci_ymls',
  },
  {
    key: 'dockerfile_names',
    name: __('Dockerfile'),
    pattern: /(Dockerfile)/,
    type: 'dockerfiles',
  },
  {
    key: 'licenses',
    name: 'LICENSE',
    pattern: /^(.+\/)?(licen[sc]e|copying)($|\.)/i,
    type: 'licenses',
  },
];

export default {
  name: 'TemplateSelector',
  components: {
    GlCollapsibleListbox,
  },
  props: {
    filename: {
      type: String,
      required: true,
    },
    templates: {
      type: Object,
      required: true,
    },
    initialTemplate: {
      type: String,
      required: false,
      default: undefined,
    },
  },
  data() {
    return {
      loading: false,
      searchTerm: '',
      selectedTemplate: undefined,
      types: templateSelectors,
    };
  },
  computed: {
    activeType() {
      return templateSelectors.find((selector) => selector.pattern.test(this.filename));
    },
    activeTemplatesList() {
      return this.templates[this.activeType?.key];
    },
    selectedTemplateKey() {
      return this.selectedTemplate?.key;
    },
    dropdownToggleText() {
      return this.selectedTemplate?.name || this.$options.i18n.templateSelectorTxt;
    },
    dropdownItems() {
      return Object.entries(this.activeTemplatesList)
        .map(([key, items]) => ({
          text: key,
          options: items
            .filter((item) => item.name.toLowerCase().includes(this.searchTerm))
            .map((item) => ({
              text: item.name,
              value: item.key,
            })),
        }))
        .filter((group) => group.options.length > 0);
    },
    templateItems() {
      return Object.values(this.activeTemplatesList).reduce((acc, items) => [...acc, ...items], []);
    },
    showDropdown() {
      return this.activeType && this.templateItems.length > 0;
    },
  },
  beforeMount() {
    if (this.activeType) this.applyTemplate(this.initialTemplate);
  },
  methods: {
    applyTemplate(templateKey) {
      this.selectedTemplate = this.templateItems.find((item) => item.key === templateKey);
      if (this.selectedTemplate) {
        this.loading = true;
        this.$emit('selected', {
          template: this.selectedTemplate,
          type: this.activeType,
          clearSelectedTemplate: this.clearSelectedTemplate,
          stopLoading: this.stopLoading,
        });
      }
    },
    stopLoading() {
      this.loading = false;
    },
    clearSelectedTemplate() {
      this.selectedTemplate = undefined;
    },
    onSearch(searchTerm) {
      this.searchTerm = searchTerm.trim().toLowerCase();
    },
  },
  i18n: {
    templateSelectorTxt: __('Apply a template'),
    searchPlaceholder: __('Filter'),
  },
};
</script>
<template>
  <div v-if="showDropdown">
    <gl-collapsible-listbox
      id="template-selector"
      searchable
      block
      class="gl-font-regular"
      data-testid="template-selector"
      :toggle-text="dropdownToggleText"
      :search-placeholder="$options.i18n.searchPlaceholder"
      :items="dropdownItems"
      :selected="selectedTemplateKey"
      :loading="loading"
      @select="applyTemplate"
      @search="onSearch"
    />
  </div>
</template>

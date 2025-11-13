<script>
import { GlCollapsibleListbox, GlButton } from '@gitlab/ui';
import { escape } from 'lodash';
import { __, sprintf } from '~/locale';
import axios from '~/lib/utils/axios_utils';
import SafeHtml from '~/vue_shared/directives/safe_html';
import { InternalEvents } from '~/tracking';
import { getParameterByName } from '~/lib/utils/url_utility';

const trackingMixin = InternalEvents.mixin();

export default {
  components: {
    GlCollapsibleListbox,
    GlButton,
  },
  directives: {
    SafeHtml,
  },
  mixins: [trackingMixin],
  inject: ['templatesUrl'],
  props: {
    templates: {
      type: Array,
      required: true,
    },
    format: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      searchTerm: '',
      selectedTemplatePath: null,
    };
  },
  computed: {
    templatesList() {
      return this.templates
        .filter((template) => template.format === this.format)
        .map((template) => ({
          text: template.title,
          value: `${template.path}/raw`,
        }))
        .filter(({ text }) => text.toLowerCase().includes(this.searchTerm.toLowerCase()));
    },
    toggleText() {
      const selectedTemplateLabel = this.templatesList.find(
        ({ value }) => value === this.selectedTemplatePath,
      )?.text;

      return selectedTemplateLabel
        ? sprintf(__('Template: %{title}'), { title: selectedTemplateLabel })
        : __('Choose a template');
    },
  },
  mounted() {
    this.autoSelectTemplate();
  },
  methods: {
    autoSelectTemplate() {
      const selectedTemplateSlug = getParameterByName('selected_template_slug');
      if (!selectedTemplateSlug) return;

      const selected = this.templates.find((template) => template.slug === selectedTemplateSlug);
      if (!selected) return;

      const selectedTemplatePath = `${selected.path}/raw`;
      this.selectTemplate(selectedTemplatePath);
    },
    filterTemplates(searchTerm) {
      this.searchTerm = searchTerm;
    },
    async selectTemplate(templatePath) {
      this.selectedTemplatePath = templatePath;

      const template = await axios.get(templatePath);
      this.trackEvent('apply_wiki_template');
      this.$emit('input', template.data);
    },
    highlight(text) {
      return this.searchTerm
        ? String(escape(text)).replace(
            new RegExp(this.searchTerm, 'i'),
            (match) => `<strong>${match}</strong>`,
          )
        : escape(text);
    },
  },
  i18n: {
    searchTemplates: __('Search templates'),
    noMatchingTemplates: __('No matching templates'),
    chooseTemplate: __('Choose a template'),
  },
  safeHtmlConfig: { ALLOWED_TAGS: ['strong'] },
};
</script>

<template>
  <gl-collapsible-listbox
    v-model="selectedTemplatePath"
    :items="templatesList"
    searchable
    block
    :toggle-text="toggleText"
    :search-placeholder="$options.i18n.searchTemplates"
    :no-results-text="$options.i18n.noMatchingTemplates"
    :header-text="$options.i18n.chooseTemplate"
    @search="filterTemplates"
    @select="selectTemplate"
  >
    <template #list-item="{ item }">
      <span v-safe-html:[$options.safeHtmlConfig]="highlight(item.text)"> </span>
    </template>
    <template #footer>
      <div class="gl-border-t gl-px-2 gl-py-2">
        <gl-button
          data-testid="manage-templates-link"
          :href="templatesUrl"
          target="_blank"
          block
          class="!gl-justify-start"
          category="tertiary"
          >{{ __('Manage templates…') }}</gl-button
        >
      </div>
    </template>
  </gl-collapsible-listbox>
</template>

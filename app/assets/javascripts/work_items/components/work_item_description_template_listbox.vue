<script>
import { GlCollapsibleListbox, GlSkeletonLoader, GlSprintf, GlLink, GlButton } from '@gitlab/ui';
import * as Sentry from '~/sentry/sentry_browser_wrapper';
import { s__ } from '~/locale';
import { helpPagePath } from '~/helpers/help_page_helper';
import workItemDescriptionTemplatesListQuery from '../graphql/work_item_description_templates_list.query.graphql';

export default {
  name: 'WorkItemDescriptionTemplateListbox',
  components: {
    GlCollapsibleListbox,
    GlSkeletonLoader,
    GlSprintf,
    GlLink,
    GlButton,
  },
  props: {
    fullPath: {
      type: String,
      required: true,
    },
    template: {
      type: String,
      required: false,
      default: null,
    },
  },
  data() {
    return {
      descriptionTemplates: [],
      searchTerm: '',
    };
  },
  apollo: {
    descriptionTemplates: {
      query: workItemDescriptionTemplatesListQuery,
      variables() {
        return {
          fullPath: this.fullPath,
        };
      },
      update(data) {
        return data.namespace?.workItemDescriptionTemplates.nodes || [];
      },
      error(e) {
        Sentry.captureException(e);
      },
    },
  },
  computed: {
    loading() {
      return this.$apollo.queries.descriptionTemplates.loading;
    },
    toggleText() {
      return this.template || s__('WorkItem|Choose a template');
    },
    hasTemplates() {
      return this.descriptionTemplates.length > 0;
    },
    items() {
      const listboxItems = this.descriptionTemplates.map(({ name }) => ({
        value: name,
        text: name,
      }));
      if (this.searchTerm) {
        return listboxItems.filter(({ text }) => text.includes(this.searchTerm));
      }
      return listboxItems;
    },
  },
  methods: {
    handleSelect(item) {
      this.$emit('selectTemplate', item);
    },
    handleSearch(searchTerm) {
      this.searchTerm = searchTerm;
    },
    handleReset() {
      this.$refs.listbox?.closeAndFocus();
      this.$emit('reset');
    },
  },
  templateDocsPath: helpPagePath('user/project/description_templates'),
};
</script>

<template>
  <gl-skeleton-loader v-if="loading" />

  <gl-collapsible-listbox
    v-else-if="hasTemplates"
    ref="listbox"
    :items="items"
    :toggle-text="toggleText"
    :header-text="s__('WorkItem|Select template')"
    size="small"
    :selected="template"
    :loading="loading"
    searchable
    @select="handleSelect"
    @search="handleSearch"
  >
    <template #footer>
      <div class="gl-border-t gl-border-t-dropdown gl-p-2 gl-pt-0">
        <gl-button
          category="tertiary"
          block
          data-testid="reset-template"
          class="gl-mt-2 !gl-justify-start"
          @click="handleReset"
        >
          {{ s__('WorkItem|Reset template') }}
        </gl-button>
      </div>
    </template>
  </gl-collapsible-listbox>

  <p v-else data-testid="template-message">
    <gl-sprintf
      :message="
        s__(
          'WorkItem|Add %{linkStart}description templates%{linkEnd} to help your contributors communicate effectively!',
        )
      "
    >
      <template #link="{ content }">
        <gl-link :href="$options.templateDocsPath">
          {{ content }}
        </gl-link>
      </template>
    </gl-sprintf>
  </p>
</template>

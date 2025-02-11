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
      type: Object,
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
        return data.namespace?.workItemDescriptionTemplates?.nodes || [];
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
      return this.template?.name || s__('WorkItem|Choose a template');
    },
    hasTemplates() {
      return this.descriptionTemplates.length > 0;
    },
    selectedTemplateValue() {
      if (!this.template) {
        return undefined;
      }
      if (this.template?.projectId && this.template?.category) {
        return this.makeTemplateValue(this.template);
      }
      if (this.template.name && this.template.projectId === null) {
        const closestMatch = this.items
          .flatMap((group) => group.options)
          .find((option) => option.text === this.template.name);
        return closestMatch?.value;
      }
      return undefined;
    },
    items() {
      return this.descriptionTemplates
        .filter(({ name }) =>
          this.searchTerm ? name.toLowerCase().includes(this.searchTerm.toLowerCase()) : true,
        )
        .reduce((groups, current) => {
          const idx = groups.findIndex((group) => group.text === current.category);
          if (idx > -1) {
            groups[idx].options.push({
              value: this.makeTemplateValue(current),
              text: current.name,
            });
          } else {
            groups.push({
              text: current.category,
              options: [{ value: this.makeTemplateValue(current), text: current.name }],
            });
          }
          return groups;
        }, []);
    },
  },
  watch: {
    selectedTemplateValue(value) {
      if (value) {
        this.handleSelect(value);
      }
    },
  },
  methods: {
    handleSelect(item) {
      const { name, projectId, category } = JSON.parse(item);
      this.$emit('selectTemplate', { name, projectId, category });
    },
    handleSearch(searchTerm) {
      this.searchTerm = searchTerm;
    },
    handleClear() {
      this.$refs.listbox?.closeAndFocus();
      this.$emit('clear');
    },
    handleReset() {
      this.$refs.listbox?.closeAndFocus();
      this.$emit('reset');
    },
    makeTemplateValue({ name, category, projectId }) {
      return JSON.stringify({ name, category, projectId });
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
    :selected="selectedTemplateValue"
    :loading="loading"
    searchable
    block
    class="gl-w-30"
    @select="handleSelect"
    @search="handleSearch"
  >
    <template #list-item="{ item }">
      <span class="gl-break-words">
        {{ item.text }}
      </span>
    </template>
    <template #footer>
      <div class="gl-border-t gl-border-t-dropdown gl-p-2 gl-pt-0">
        <gl-button
          category="tertiary"
          block
          data-testid="clear-template"
          class="gl-mt-2 !gl-justify-start"
          @click="handleClear"
        >
          {{ s__('WorkItem|No template') }}
        </gl-button>
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

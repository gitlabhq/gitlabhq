<script>
import { GlButton, GlLink, GlSprintf, GlTooltipDirective } from '@gitlab/ui';
import { __, s__ } from '~/locale';
import TimeAgo from '~/vue_shared/components/time_ago_tooltip.vue';
import PageHeading from '~/vue_shared/components/page_heading.vue';
import WikiMoreDropdown from './wiki_more_dropdown.vue';

export default {
  components: {
    GlButton,
    GlLink,
    GlSprintf,
    WikiMoreDropdown,
    TimeAgo,
    PageHeading,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  inject: [
    'pageHeading',
    'showEditButton',
    'isPageTemplate',
    'editButtonUrl',
    'lastVersion',
    'pageVersion',
    'authorUrl',
    'isEditingPath',
    'wikiUrl',
    'pagePersisted',
  ],
  computed: {
    pageHeadingComputed() {
      let { pageHeading } = this;

      if (this.isEditingPath) {
        if (this.wikiUrl.endsWith('_sidebar')) {
          pageHeading = this.pagePersisted
            ? this.$options.i18n.editSidebar
            : this.$options.i18n.newSidebar;
        } else if (this.isPageTemplate) {
          pageHeading = this.pagePersisted
            ? this.$options.i18n.editTemplate
            : this.$options.i18n.newTemplate;
        } else {
          pageHeading = this.pagePersisted
            ? this.$options.i18n.editPage
            : this.$options.i18n.newPage;
        }
      }

      return pageHeading;
    },
    editTooltipText() {
      return this.isPageTemplate ? this.$options.i18n.editTemplate : this.$options.i18n.editPage;
    },
    editTooltip() {
      return `${this.editTooltipText} <kbd class='flat ml-1' aria-hidden=true>e</kbd>`;
    },
  },
  mounted() {
    if (this.editButtonUrl) {
      document.addEventListener('keyup', this.onKeyUp);
    }
  },
  destroyed() {
    document.removeEventListener('keyup', this.onKeyUp);
  },
  methods: {
    onKeyUp(event) {
      if (event.key === 'e') {
        this.$emit('is-editing', true);
      }

      return false;
    },
    setEditingMode() {
      this.$emit('is-editing', true);
    },
  },
  i18n: {
    edit: __('Edit'),
    newPage: s__('Wiki|New page'),
    editPage: s__('Wiki|Edit page'),
    newTemplate: s__('Wiki|New template'),
    editTemplate: s__('Wiki|Edit template'),
    newSidebar: s__('Wiki|New custom sidebar'),
    editSidebar: s__('Wiki|Edit custom sidebar'),
    lastEdited: s__('Wiki|Last edited by %{author} %{timeago}'),
  },
};
</script>

<template>
  <div
    class="wiki-page-header has-sidebar-toggle detail-page-header border-bottom-0 !gl-pt-0 gl-flex gl-flex-wrap"
  >
    <page-heading :heading="pageHeadingComputed" class="gl-w-full">
      <template v-if="!isEditingPath" #actions>
        <gl-button
          v-if="showEditButton"
          v-gl-tooltip.html
          :title="editTooltip"
          data-testid="wiki-edit-button"
          @click="setEditingMode"
        >
          {{ $options.i18n.edit }}
        </gl-button>
        <gl-button
          v-gl-tooltip.html
          icon="chevron-double-lg-left"
          class="js-sidebar-wiki-toggle md:gl-hidden"
        />
        <wiki-more-dropdown />
      </template>
    </page-heading>
    <div
      v-if="lastVersion"
      class="wiki-last-version gl-leading-20 gl-text-secondary gl-mt-3 gl-mb-5"
      data-testid="wiki-page-last-version"
    >
      <gl-sprintf :message="$options.i18n.lastEdited">
        <template #author>
          <gl-link :href="authorUrl" class="gl-text-black-normal gl-font-bold">{{
            pageVersion.commit.author_name
          }}</gl-link>
        </template>
        <template #timeago>
          <time-ago :time="pageVersion.commit.authored_date" target="wiki-last-version" />
        </template>
      </gl-sprintf>
    </div>
  </div>
</template>

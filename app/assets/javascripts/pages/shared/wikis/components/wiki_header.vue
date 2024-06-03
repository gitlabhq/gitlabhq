<script>
import { GlButton, GlLink, GlSprintf, GlTooltipDirective } from '@gitlab/ui';
import { __, s__ } from '~/locale';
import TimeAgo from '~/vue_shared/components/time_ago_tooltip.vue';
import WikiMoreDropdown from './wiki_more_dropdown.vue';

export default {
  components: {
    GlButton,
    GlLink,
    GlSprintf,
    WikiMoreDropdown,
    TimeAgo,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  inject: [
    'pageTitle',
    'showEditButton',
    'isPageTemplate',
    'editButtonUrl',
    'lastVersion',
    'pageVersion',
    'authorUrl',
  ],
  computed: {
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
        window.location.href = this.editButtonUrl;
      }

      return false;
    },
  },
  i18n: {
    edit: __('Edit'),
    editPage: __('Edit page'),
    editTemplate: __('Edit template'),
    lastEdited: s__('Wiki|Last edited by %{author} %{timeago}'),
  },
};
</script>

<template>
  <div
    class="wiki-page-header has-sidebar-toggle detail-page-header border-bottom-0 gl-pt-5 gl-flex gl-flex-wrap"
  >
    <div class="gl-flex gl-w-full">
      <h1
        class="gl-heading-1 !gl-my-0 gl-inline-block gl-grow gl-break-anywhere"
        data-testid="wiki-page-title"
      >
        {{ pageTitle }}
      </h1>
      <div class="detail-page-header-actions gl-self-start gl-flex gl-gap-3">
        <gl-button
          v-if="showEditButton"
          v-gl-tooltip.html
          :title="editTooltip"
          :href="editButtonUrl"
          data-testid="wiki-edit-button"
        >
          {{ $options.i18n.edit }}
        </gl-button>
        <gl-button
          v-gl-tooltip.html
          icon="chevron-double-lg-left"
          class="js-sidebar-wiki-toggle md:gl-hidden"
        />
        <wiki-more-dropdown />
      </div>
    </div>
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

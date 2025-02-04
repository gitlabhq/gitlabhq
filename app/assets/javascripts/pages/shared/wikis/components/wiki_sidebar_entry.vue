<script>
import { GlIcon, GlButton, GlLink } from '@gitlab/ui';
import { escape } from 'lodash';
import LocalStorageSync from '~/vue_shared/components/local_storage_sync.vue';
import { s__, sprintf } from '~/locale';
import SafeHtml from '~/vue_shared/directives/safe_html';

export default {
  name: 'WikiSidebarEntry',
  components: {
    GlIcon,
    GlLink,
    GlButton,
    LocalStorageSync,
  },
  directives: {
    SafeHtml,
  },
  inject: ['canCreate'],
  props: {
    page: {
      type: Object,
      required: true,
    },
    searchTerm: {
      type: String,
      default: '',
      required: false,
    },
  },
  data() {
    return {
      isCollapsed: false,
    };
  },
  computed: {
    plusButtonTooltip() {
      return sprintf(s__('Wiki|Create a new page under "%{page_title}"'), {
        page_title: this.page.title,
      });
    },
    currentPath() {
      return window.location.pathname;
    },
    pageTitle() {
      if (this.page.title === 'home') return s__('Wiki|Home');
      return this.page.title;
    },
  },
  methods: {
    toggleCollapsed() {
      this.isCollapsed = !this.isCollapsed;
    },
    highlight(text) {
      if (!this.searchTerm) {
        return escape(text);
      }

      const escapedText = escape(text);
      const regex = new RegExp(`(${this.searchTerm})`, 'i');
      return `${escapedText.replace(
        regex,
        (match) => `<span class="gl-bg-status-warning">${match}</span>`,
      )}`;
    },
  },
  safeHtmlConfig: { ALLOWED_TAGS: ['span'] },
};
</script>
<template>
  <li dir="auto" :data-testid="page.children.length ? 'wiki-directory-content' : ''">
    <local-storage-sync v-model="isCollapsed" :storage-key="`wiki:${page.path}:collapsed`" />
    <span
      ref="entry"
      class="wiki-list gl-relative gl-mx-2 gl-mb-px gl-flex gl-min-h-8 gl-cursor-pointer gl-items-center gl-rounded-base gl-px-3"
      data-testid="wiki-list"
      :class="{ active: page.path === currentPath }"
      @click="toggleCollapsed"
    >
      <gl-link
        v-safe-html:[$options.safeHtmlConfig]="highlight(pageTitle)"
        :href="page.path"
        class="gl-str-truncated"
        :data-qa-page-name="pageTitle"
        :data-testid="page.children.length ? 'wiki-dir-page-link' : 'wiki-page-link'"
        @click.stop
      />
      <gl-button
        v-if="canCreate"
        icon="plus"
        size="small"
        category="tertiary"
        data-testid="wiki-list-create-child-button"
        :href="`${page.path}/{new_page_title}`"
        class="wiki-list-create-child-button has-tooltip gl-ml-2"
        :title="plusButtonTooltip"
        :aria-label="plusButtonTooltip"
        @click.stop
      />
      <gl-icon
        v-if="page.children.length"
        :name="isCollapsed ? 'chevron-right' : 'chevron-down'"
        class="gl-absolute gl-right-2 gl-ml-2"
        variant="subtle"
      />
    </span>
    <ul v-if="page.children.length && !isCollapsed" dir="auto" class="!gl-pl-5">
      <wiki-sidebar-entry
        v-for="child in page.children"
        :key="child.slug"
        :page="child"
        :search-term="searchTerm"
      />
    </ul>
  </li>
</template>

<script>
import { GlIcon, GlButton, GlLink } from '@gitlab/ui';
import { s__, sprintf } from '~/locale';

export default {
  name: 'WikiSidebarEntry',
  components: {
    GlIcon,
    GlLink,
    GlButton,
  },
  inject: ['canCreate'],
  props: {
    page: {
      type: Object,
      required: true,
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
  },
};
</script>
<template>
  <li dir="auto" :data-testid="page.children.length ? 'wiki-directory-content' : ''">
    <span
      ref="entry"
      class="gl-relative gl-flex gl-items-center wiki-list gl-px-3 gl-rounded-base gl-cursor-pointer"
      data-testid="wiki-list"
      :class="{ active: page.path === currentPath }"
      @click="toggleCollapsed"
    >
      <gl-link
        :href="page.path"
        class="gl-str-truncated"
        :data-qa-page-name="pageTitle"
        :data-testid="page.children.length ? 'wiki-dir-page-link' : 'wiki-page-link'"
        @click.stop
      >
        {{ pageTitle }}
      </gl-link>
      <gl-button
        v-if="canCreate"
        icon="plus"
        size="small"
        category="tertiary"
        data-testid="wiki-list-create-child-button"
        :href="`${page.path}/{new_page_title}`"
        class="wiki-list-create-child-button gl-ml-2 has-tooltip"
        :title="plusButtonTooltip"
        :aria-label="plusButtonTooltip"
        @click.stop
      />
      <gl-icon
        v-if="page.children.length"
        :name="isCollapsed ? 'chevron-right' : 'chevron-down'"
        class="gl-ml-2 gl-absolute gl-right-2 gl-text-secondary"
      />
    </span>
    <ul v-if="page.children.length && !isCollapsed" dir="auto" class="!gl-pl-5">
      <wiki-sidebar-entry v-for="child in page.children" :key="child.slug" :page="child" />
    </ul>
  </li>
</template>

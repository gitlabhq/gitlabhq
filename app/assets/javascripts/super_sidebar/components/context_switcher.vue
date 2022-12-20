<script>
import { GlAvatar, GlSearchBoxByType } from '@gitlab/ui';
import { s__ } from '~/locale';
import { contextSwitcherItems } from '../mock_data';
import NavItem from './nav_item.vue';

export default {
  components: {
    GlAvatar,
    GlSearchBoxByType,
    NavItem,
  },
  i18n: {
    contextNavigation: s__('Navigation|Context navigation'),
    switchTo: s__('Navigation|Switch to...'),
    recentProjects: s__('Navigation|Recent projects'),
    recentGroups: s__('Navigation|Recent groups'),
  },
  contextSwitcherItems,
  viewAllProjectsItem: {
    title: s__('Navigation|View all projects'),
    link: '/projects',
    icon: 'project',
  },
  viewAllGroupsItem: {
    title: s__('Navigation|View all groups'),
    link: '/groups',
    icon: 'group',
  },
};
</script>

<template>
  <div>
    <gl-search-box-by-type />
    <nav :aria-label="$options.i18n.contextNavigation">
      <ul class="gl-p-0 gl-list-style-none">
        <li>
          <div aria-hidden="true" class="gl-font-weight-bold gl-px-3 gl-py-3">
            {{ $options.i18n.switchTo }}
          </div>
          <ul :aria-label="$options.i18n.switchTo" class="gl-p-0">
            <nav-item :item="$options.contextSwitcherItems.yourWork" />
          </ul>
        </li>
        <li>
          <div aria-hidden="true" class="gl-font-weight-bold gl-px-3 gl-py-3">
            {{ $options.i18n.recentProjects }}
          </div>
          <ul :aria-label="$options.i18n.recentProjects" class="gl-p-0">
            <nav-item
              v-for="project in $options.contextSwitcherItems.recentProjects"
              :key="project.title"
              :item="project"
            >
              <template #icon>
                <gl-avatar shape="rect" :size="32" :src="project.avatar" />
              </template>
            </nav-item>
            <nav-item :item="$options.viewAllProjectsItem" />
          </ul>
        </li>
        <li>
          <div aria-hidden="true" class="gl-font-weight-bold gl-px-3 gl-py-3">
            {{ $options.i18n.recentGroups }}
          </div>
          <ul :aria-label="$options.i18n.recentGroups" class="gl-p-0">
            <nav-item
              v-for="project in $options.contextSwitcherItems.recentGroups"
              :key="project.title"
              :item="project"
            >
              <template #icon>
                <gl-avatar shape="rect" :size="32" :src="project.avatar" />
              </template>
            </nav-item>
            <nav-item :item="$options.viewAllGroupsItem" />
          </ul>
        </li>
      </ul>
    </nav>
  </div>
</template>

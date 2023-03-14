<script>
import { GlSearchBoxByType } from '@gitlab/ui';
import { s__ } from '~/locale';
import { contextSwitcherItems } from '../mock_data';
import NavItem from './nav_item.vue';
import FrequentProjectsList from './frequent_projects_list.vue';
import FrequentGroupsList from './frequent_groups_list.vue';

export default {
  i18n: {
    contextNavigation: s__('Navigation|Context navigation'),
    switchTo: s__('Navigation|Switch to...'),
  },
  components: {
    GlSearchBoxByType,
    NavItem,
    FrequentProjectsList,
    FrequentGroupsList,
  },
  props: {
    username: {
      type: String,
      required: true,
    },
    projectsPath: {
      type: String,
      required: true,
    },
    groupsPath: {
      type: String,
      required: true,
    },
  },
  contextSwitcherItems,
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
            <nav-item :item="$options.contextSwitcherItems.explore" />
          </ul>
        </li>
        <frequent-projects-list :username="username" :view-all-link="projectsPath" />
        <frequent-groups-list :username="username" :view-all-link="groupsPath" />
      </ul>
    </nav>
  </div>
</template>

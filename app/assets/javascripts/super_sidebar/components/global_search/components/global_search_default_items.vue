<script>
import {
  FREQUENTLY_VISITED_PROJECTS_HANDLE,
  FREQUENTLY_VISITED_GROUPS_HANDLE,
} from '~/super_sidebar/components/global_search/command_palette/constants';

import {
  EVENT_CLICK_FREQUENT_GROUP_IN_COMMAND_PALETTE,
  EVENT_CLICK_FREQUENT_PROJECT_IN_COMMAND_PALETTE,
} from '~/super_sidebar/components/global_search/tracking_constants';

import { InternalEvents } from '~/tracking';
import DefaultPlaces from './global_search_default_places.vue';
import DefaultIssuables from './global_search_default_issuables.vue';
import FrequentGroups from './frequent_groups.vue';
import FrequentProjects from './frequent_projects.vue';

const components = [DefaultPlaces, FrequentProjects, FrequentGroups, DefaultIssuables];
const trackingMixin = InternalEvents.mixin();

export default {
  name: 'GlobalSearchDefaultItems',
  mixins: [trackingMixin],
  data() {
    return {
      // The components here are expected to:
      // - be responsible for getting their own data,
      // - render a GlDisclosureDropdownGroup as the root vnode,
      // - transparently pass all attrs to it (e.g., `bordered`),
      // - not render anything if they have no data,
      // - emit a `nothing-to-render` event if they have nothing to render.
      // - have a unique `name`
      componentNames: components.map(({ name }) => name),
    };
  },
  methods: {
    componentFromName(name) {
      return components.find((component) => component.name === name);
    },
    remove(nameToRemove) {
      const indexToRemove = this.componentNames.findIndex((name) => name === nameToRemove);
      if (indexToRemove !== -1) this.componentNames.splice(indexToRemove, 1);
    },
    attrs(index) {
      return index === 0
        ? null
        : {
            bordered: true,
            class: 'gl-mt-3',
          };
    },
    trackItems(type) {
      switch (type) {
        case FREQUENTLY_VISITED_PROJECTS_HANDLE: {
          this.trackEvent(EVENT_CLICK_FREQUENT_PROJECT_IN_COMMAND_PALETTE);
          break;
        }
        case FREQUENTLY_VISITED_GROUPS_HANDLE: {
          this.trackEvent(EVENT_CLICK_FREQUENT_GROUP_IN_COMMAND_PALETTE);
          break;
        }
        default: {
          break;
        }
      }
    },
  },
};
</script>

<template>
  <ul class="gl-m-0 gl-list-none gl-p-0 gl-pt-2">
    <component
      :is="componentFromName(name)"
      v-for="(name, index) in componentNames"
      :key="name"
      v-bind="attrs(index)"
      @nothing-to-render="remove(name)"
      @action="trackItems"
    />
  </ul>
</template>

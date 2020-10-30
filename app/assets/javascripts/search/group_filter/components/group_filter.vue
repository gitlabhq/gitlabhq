<script>
import {
  GlDropdown,
  GlDropdownItem,
  GlSearchBoxByType,
  GlLoadingIcon,
  GlIcon,
  GlSkeletonLoader,
  GlTooltipDirective,
} from '@gitlab/ui';
import { mapState, mapActions } from 'vuex';
import { isEmpty } from 'lodash';
import { visitUrl, setUrlParams } from '~/lib/utils/url_utility';
import { ANY_GROUP, GROUP_QUERY_PARAM, PROJECT_QUERY_PARAM } from '../constants';

export default {
  name: 'GroupFilter',
  components: {
    GlDropdown,
    GlDropdownItem,
    GlSearchBoxByType,
    GlLoadingIcon,
    GlIcon,
    GlSkeletonLoader,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  props: {
    initialGroup: {
      type: Object,
      required: false,
      default: () => ({}),
    },
  },
  data() {
    return {
      groupSearch: '',
    };
  },
  computed: {
    ...mapState(['groups', 'fetchingGroups']),
    selectedGroup: {
      get() {
        return isEmpty(this.initialGroup) ? ANY_GROUP : this.initialGroup;
      },
      set(group) {
        visitUrl(setUrlParams({ [GROUP_QUERY_PARAM]: group.id, [PROJECT_QUERY_PARAM]: null }));
      },
    },
  },
  methods: {
    ...mapActions(['fetchGroups']),
    isGroupSelected(group) {
      return group.id === this.selectedGroup.id;
    },
    handleGroupChange(group) {
      this.selectedGroup = group;
    },
  },
  ANY_GROUP,
};
</script>

<template>
  <gl-dropdown
    ref="groupFilter"
    class="gl-w-full"
    menu-class="gl-w-full!"
    toggle-class="gl-text-truncate gl-reset-line-height!"
    :header-text="__('Filter results by group')"
    @show="fetchGroups(groupSearch)"
  >
    <template #button-content>
      <span class="dropdown-toggle-text gl-flex-grow-1 gl-text-truncate">
        {{ selectedGroup.name }}
      </span>
      <gl-loading-icon v-if="fetchingGroups" inline class="mr-2" />
      <gl-icon
        v-if="!isGroupSelected($options.ANY_GROUP)"
        v-gl-tooltip
        name="clear"
        :title="__('Clear')"
        class="gl-text-gray-200! gl-hover-text-blue-800!"
        @click.stop="handleGroupChange($options.ANY_GROUP)"
      />
      <gl-icon name="chevron-down" />
    </template>
    <div class="gl-sticky gl-top-0 gl-z-index-1 gl-bg-white">
      <gl-search-box-by-type
        v-model="groupSearch"
        class="m-2"
        :debounce="500"
        @input="fetchGroups"
      />
      <gl-dropdown-item
        class="gl-border-b-solid gl-border-b-gray-100 gl-border-b-1 gl-pb-2! gl-mb-2"
        :is-check-item="true"
        :is-checked="isGroupSelected($options.ANY_GROUP)"
        @click="handleGroupChange($options.ANY_GROUP)"
      >
        {{ $options.ANY_GROUP.name }}
      </gl-dropdown-item>
    </div>
    <div v-if="!fetchingGroups">
      <gl-dropdown-item
        v-for="group in groups"
        :key="group.id"
        :is-check-item="true"
        :is-checked="isGroupSelected(group)"
        @click="handleGroupChange(group)"
      >
        {{ group.full_name }}
      </gl-dropdown-item>
    </div>
    <div v-if="fetchingGroups" class="mx-3 mt-2">
      <gl-skeleton-loader :height="100">
        <rect y="0" width="90%" height="20" rx="4" />
        <rect y="40" width="70%" height="20" rx="4" />
        <rect y="80" width="80%" height="20" rx="4" />
      </gl-skeleton-loader>
    </div>
  </gl-dropdown>
</template>

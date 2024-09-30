<script>
import { GlDrawer, GlButton } from '@gitlab/ui';
import { DRAWER_Z_INDEX } from '~/lib/utils/constants';
import { getContentWrapperHeight } from '~/lib/utils/dom_utils';
import { __ } from '~/locale';
import ListSelector from '~/vue_shared/components/list_selector/index.vue';
import { GROUPS_TYPE, PROJECTS_TYPE } from '~/vue_shared/components/list_selector/constants';

export default {
  DRAWER_Z_INDEX,
  GROUPS_TYPE,
  PROJECTS_TYPE,
  components: {
    GlDrawer,
    GlButton,
    ListSelector,
  },
  props: {
    isOpen: {
      type: Boolean,
      required: true,
    },
  },
  data() {
    return {
      isLoading: false,
      exclusions: [],
    };
  },
  computed: {
    getDrawerHeaderHeight() {
      return getContentWrapperHeight();
    },
    groupExclusions() {
      return this.exclusions.filter((exclusion) => exclusion.type === 'group');
    },
    projectExclusions() {
      return this.exclusions.filter((exclusion) => exclusion.type === 'project');
    },
  },
  methods: {
    handleSelectExclusion(exclusion) {
      this.exclusions.push({ ...exclusion });
    },
    handleRemoveExclusion(id) {
      const exclusionIndex = this.exclusions.findIndex((exclusion) => exclusion.id === id);
      this.exclusions.splice(exclusionIndex, 1);
    },
    async handleAddExclusions() {
      this.isLoading = true;
      this.$emit('add', this.exclusions);
      this.exclusions = [];
      this.isLoading = false;
    },
  },
  i18n: {
    addExclusions: __('Add exclusions'),
  },
};
</script>

<template>
  <gl-drawer
    :header-height="getDrawerHeaderHeight"
    :z-index="$options.DRAWER_Z_INDEX"
    :open="isOpen"
    v-on="$listeners"
  >
    <template #title>
      <h2 class="gl-mt-0 gl-text-size-h2" data-testid="title">{{ $options.i18n.addExclusions }}</h2>
    </template>

    <template #default>
      <list-selector
        :type="$options.GROUPS_TYPE"
        class="gl-m-5 !gl-p-0"
        autofocus
        disable-namespace-dropdown
        :selected-items="groupExclusions"
        @select="handleSelectExclusion"
        @delete="handleRemoveExclusion"
      />

      <list-selector
        :type="$options.PROJECTS_TYPE"
        class="gl-m-5 !gl-p-0"
        :selected-items="projectExclusions"
        @select="handleSelectExclusion"
        @delete="handleRemoveExclusion"
      />

      <gl-button
        class="gl-ml-5"
        variant="confirm"
        :loading="isLoading"
        data-testid="add-button"
        @click="handleAddExclusions"
      >
        {{ $options.i18n.addExclusions }}
      </gl-button>
    </template>
  </gl-drawer>
</template>

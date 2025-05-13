<script>
import {
  GlTooltipDirective,
  GlBadge,
  GlButtonGroup,
  GlButton,
  GlSearchBoxByType,
} from '@gitlab/ui';
import { getModifierKey } from '~/constants';
import { __, s__, sprintf } from '~/locale';

export default {
  i18n: {
    listViewToggleTitle: __('List view'),
    treeViewToggleTitle: __('Tree view'),
  },
  directives: {
    GlTooltip: GlTooltipDirective,
  },
  components: {
    GlBadge,
    GlButtonGroup,
    GlButton,
    GlSearchBoxByType,
  },
  props: {
    totalFilesCount: {
      type: Number,
      required: true,
    },
  },
  data() {
    return {
      search: '',
      renderTreeList: false,
    };
  },
  searchPlaceholder: sprintf(s__('Repository|Search (e.g. *.vue) (%{modifierKey}P)'), {
    modifierKey: getModifierKey(),
  }),
};
</script>

<template>
  <div class="tree-list-holder">
    <div class="gl-mb-3 gl-flex gl-items-center">
      <h5 class="gl-my-0 gl-inline-block">{{ __('Files') }}</h5>
      <gl-badge class="gl-ml-2">{{ totalFilesCount }}</gl-badge>
      <gl-button-group class="gl-ml-auto">
        <gl-button
          v-gl-tooltip.hover
          icon="list-bulleted"
          :selected="!renderTreeList"
          :title="$options.i18n.listViewToggleTitle"
          :aria-label="$options.i18n.listViewToggleTitle"
          @click="renderTreeList = false"
        />
        <gl-button
          v-gl-tooltip.hover
          icon="file-tree"
          :selected="renderTreeList"
          :title="$options.i18n.treeViewToggleTitle"
          :aria-label="$options.i18n.treeViewToggleTitle"
          @click="renderTreeList = true"
        />
      </gl-button-group>
    </div>
    <label for="repository-tree-search" class="sr-only">{{ $options.searchPlaceholder }}</label>
    <gl-search-box-by-type
      id="repository-tree-search"
      v-model="search"
      :placeholder="$options.searchPlaceholder"
      :clear-button-title="__('Clear search')"
      name="repository-tree-search"
      class="gl-mb-3"
    />
    <div>
      <!-- TODO: implement recycle-scroller + list files (file-row components) -->
      <p class="text-center gl-my-6">
        {{ __('No files found') }}
      </p>
    </div>
  </div>
</template>

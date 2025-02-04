<script>
import { isEmpty } from 'lodash';
import getToolbarItemsQuery from '~/editor/graphql/get_items.query.graphql';
import { EDITOR_TOOLBAR_BUTTON_GROUPS } from '~/editor/constants';
import SourceEditorToolbarButton from './source_editor_toolbar_button.vue';

export default {
  name: 'SourceEditorToolbar',
  components: {
    SourceEditorToolbarButton,
  },
  data() {
    return {
      items: [],
    };
  },
  apollo: {
    items: {
      query: getToolbarItemsQuery,
      update(data) {
        return this.setDefaultGroup(data?.items?.nodes);
      },
    },
  },
  computed: {
    isVisible() {
      return this.items.length;
    },
  },
  methods: {
    setDefaultGroup(nodes = []) {
      return nodes.map((item) => {
        return {
          ...item,
          group: EDITOR_TOOLBAR_BUTTON_GROUPS[item.group] || EDITOR_TOOLBAR_BUTTON_GROUPS.settings,
        };
      });
    },
    getGroupItems(group) {
      return this.items.filter((item) => item.group === group);
    },
    hasGroupItems(group) {
      return !isEmpty(this.getGroupItems(group));
    },
  },
  groups: EDITOR_TOOLBAR_BUTTON_GROUPS,
};
</script>
<template>
  <section
    v-if="isVisible"
    id="se-toolbar"
    class="file-buttons gl-flex gl-items-center gl-justify-end"
  >
    <div v-if="hasGroupItems($options.groups.file)">
      <source-editor-toolbar-button
        v-for="item in getGroupItems($options.groups.file)"
        :key="item.id"
        :button="item"
        @click="$emit('click', item)"
      />
    </div>
    <div
      v-if="hasGroupItems($options.groups.edit)"
      class="md-header-toolbar gl-ml-auto gl-flex gl-flex-wrap gl-gap-3"
      role="toolbar"
      :aria-label="__('Editor toolbar')"
    >
      <source-editor-toolbar-button
        v-for="item in getGroupItems($options.groups.edit)"
        :key="item.id"
        :button="item"
        @click="$emit('click', item)"
      />
    </div>
    <div v-if="hasGroupItems($options.groups.settings)" class="gl-self-start">
      <source-editor-toolbar-button
        v-for="item in getGroupItems($options.groups.settings)"
        :key="item.id"
        :button="item"
        @click="$emit('click', item)"
      />
    </div>
  </section>
</template>

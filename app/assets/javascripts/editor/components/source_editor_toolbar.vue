<script>
import { isEmpty } from 'lodash';
import { GlButtonGroup } from '@gitlab/ui';
import getToolbarItemsQuery from '~/editor/graphql/get_items.query.graphql';
import { EDITOR_TOOLBAR_BUTTON_GROUPS } from '~/editor/constants';
import SourceEditorToolbarButton from './source_editor_toolbar_button.vue';

export default {
  name: 'SourceEditorToolbar',
  components: {
    SourceEditorToolbarButton,
    GlButtonGroup,
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
    class="gl-py-3 gl-px-5 gl-bg-white gl-border-b gl-display-flex gl-align-items-center"
  >
    <gl-button-group v-if="hasGroupItems($options.groups.file)">
      <source-editor-toolbar-button
        v-for="item in getGroupItems($options.groups.file)"
        :key="item.id"
        :button="item"
        @click="$emit('click', item)"
      />
    </gl-button-group>
    <gl-button-group v-if="hasGroupItems($options.groups.edit)">
      <source-editor-toolbar-button
        v-for="item in getGroupItems($options.groups.edit)"
        :key="item.id"
        :button="item"
        @click="$emit('click', item)"
      />
    </gl-button-group>
    <gl-button-group v-if="hasGroupItems($options.groups.settings)" class="gl-ml-auto">
      <source-editor-toolbar-button
        v-for="item in getGroupItems($options.groups.settings)"
        :key="item.id"
        :button="item"
        @click="$emit('click', item)"
      />
    </gl-button-group>
  </section>
</template>

<script>
import { GlCollapsibleListbox } from '@gitlab/ui';
import { setUrlParams, visitUrl } from '~/lib/utils/url_utility';

export default {
  name: 'BackgroundMigrationsDatabaseListbox',
  components: {
    GlCollapsibleListbox,
  },
  props: {
    databases: {
      type: Array,
      required: true,
    },
    selectedDatabase: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      selected: this.selectedDatabase,
    };
  },
  methods: {
    selectDatabase(database) {
      visitUrl(setUrlParams({ database }));
    },
  },
};
</script>

<template>
  <li role="presentation" class="gl-flex gl-grow gl-items-center gl-justify-end">
    <label id="database-selector-label" class="gl-sr-only">{{ __('Selected database') }}</label>
    <gl-collapsible-listbox
      v-model="selected"
      :items="databases"
      placement="bottom-end"
      :toggle-text="selectedDatabase"
      toggle-aria-labelled-by="database-selector-label"
      @select="selectDatabase"
    />
  </li>
</template>

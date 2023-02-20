<script>
import { GlCollapsibleListbox } from '@gitlab/ui';
import { s__ } from '~/locale';
import { setUrlParams, visitUrl } from '~/lib/utils/url_utility';

export default {
  name: 'BackgroundMigrationsDatabaseListbox',
  i18n: {
    database: s__('BackgroundMigrations|Database'),
  },
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
  <div class="gl-display-flex gl-align-items-center">
    <label id="label" class="gl-font-weight-bold gl-mr-4 gl-mb-0">{{
      $options.i18n.database
    }}</label>
    <gl-collapsible-listbox
      v-model="selected"
      :items="databases"
      placement="right"
      :toggle-text="selectedDatabase"
      toggle-aria-labelled-by="label"
      @select="selectDatabase"
    />
  </div>
</template>

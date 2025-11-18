<script>
import { GlSearchBoxByClick } from '@gitlab/ui';
import { visitUrl, mergeUrlParams } from '~/lib/utils/url_utility';

export default {
  name: 'O11yServiceSettingsSearchBox',
  components: {
    GlSearchBoxByClick,
  },
  props: {
    initialValue: {
      type: String,
      default: '',
      required: false,
    },
    searchUrl: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      searchTerm: this.initialValue,
    };
  },
  methods: {
    onSubmit() {
      let url = this.searchUrl;
      if (this.searchTerm) {
        url = mergeUrlParams({ group_id: this.searchTerm }, url);
      }
      visitUrl(url);
    },
    onClear() {
      this.searchTerm = '';
      const url = this.searchUrl;
      visitUrl(url);
    },
  },
};
</script>

<template>
  <gl-search-box-by-click
    v-model="searchTerm"
    :placeholder="s__('Observability|Filter by group ID')"
    class="gl-mb-4"
    @submit="onSubmit"
    @clear="onClear"
  />
</template>

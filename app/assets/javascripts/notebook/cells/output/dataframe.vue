<script>
import JSONTable from '~/behaviors/components/json_table.vue';
import Prompt from '../prompt.vue';
import { convertHtmlTableToJson } from './dataframe_util';

export default {
  name: 'DataframeOutput',
  components: {
    Prompt,
    JSONTable,
  },
  props: {
    count: {
      type: Number,
      required: true,
    },
    rawCode: {
      type: String,
      required: true,
    },
    index: {
      type: Number,
      required: true,
    },
  },
  computed: {
    showOutput() {
      return this.index === 0;
    },
    dataframeAsJSONTable() {
      return {
        ...convertHtmlTableToJson(this.rawCode),
        caption: '',
        hasFilter: true,
      };
    },
  },
};
</script>

<template>
  <div class="output">
    <prompt type="Out" :count="count" :show-output="showOutput" />
    <j-s-o-n-table v-bind="dataframeAsJSONTable" class="gl-overflow-auto" />
  </div>
</template>

<script>
import { GlFilteredSearch } from '@gitlab/ui';
import { __, s__ } from '~/locale';
import PipelineTriggerAuthorToken from './tokens/pipeline_trigger_author_token.vue';
import PipelineBranchNameToken from './tokens/pipeline_branch_name_token.vue';
import { map } from 'lodash';

export default {
  components: {
    GlFilteredSearch,
  },
  props: {
    pipelines: {
      type: Array,
      required: true,
    },
    projectId: {
      type: String,
      required: true,
    },
    params: {
      type: Object,
      required: true,
    },
  },
  computed: {
    tokens() {
      return [
        {
          type: 'username',
          icon: 'user',
          title: s__('Pipeline|Trigger author'),
          unique: true,
          token: PipelineTriggerAuthorToken,
          operators: [{ value: '=', description: __('is'), default: 'true' }],
          projectId: this.projectId,
        },
        {
          type: 'ref',
          icon: 'branch',
          title: s__('Pipeline|Branch name'),
          unique: true,
          token: PipelineBranchNameToken,
          operators: [{ value: '=', description: __('is'), default: 'true' }],
          projectId: this.projectId,
        },
      ];
    },
    paramsValue() {
      return map(this.params, (val, key) => ({
        type: key,
        value: { data: val, operator: '=' },
      }));
    },
  },
  methods: {
    onSubmit(filters) {
      this.$emit('filterPipelines', filters);
    },
  },
};
</script>

<template>
  <div class="row-content-block">
    <gl-filtered-search
      :placeholder="__('Filter pipelines')"
      :available-tokens="tokens"
      :value="paramsValue"
      @submit="onSubmit"
    />
  </div>
</template>

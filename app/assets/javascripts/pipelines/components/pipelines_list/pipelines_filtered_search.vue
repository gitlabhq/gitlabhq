<script>
import { GlFilteredSearch } from '@gitlab/ui';
import { map } from 'lodash';
import { s__ } from '~/locale';
import { OPERATOR_IS_ONLY } from '~/vue_shared/components/filtered_search_bar/constants';
import PipelineBranchNameToken from './tokens/pipeline_branch_name_token.vue';
import PipelineStatusToken from './tokens/pipeline_status_token.vue';
import PipelineTagNameToken from './tokens/pipeline_tag_name_token.vue';
import PipelineTriggerAuthorToken from './tokens/pipeline_trigger_author_token.vue';

export default {
  userType: 'username',
  branchType: 'ref',
  tagType: 'tag',
  statusType: 'status',
  defaultTokensLength: 1,
  components: {
    GlFilteredSearch,
  },
  props: {
    projectId: {
      type: String,
      required: true,
    },
    params: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      internalValue: [],
    };
  },
  computed: {
    selectedTypes() {
      return this.value.map((i) => i.type);
    },
    tokens() {
      return [
        {
          type: this.$options.userType,
          icon: 'user',
          title: s__('Pipeline|Trigger author'),
          unique: true,
          token: PipelineTriggerAuthorToken,
          operators: OPERATOR_IS_ONLY,
          projectId: this.projectId,
        },
        {
          type: this.$options.branchType,
          icon: 'branch',
          title: s__('Pipeline|Branch name'),
          unique: true,
          token: PipelineBranchNameToken,
          operators: OPERATOR_IS_ONLY,
          projectId: this.projectId,
          disabled: this.selectedTypes.includes(this.$options.tagType),
        },
        {
          type: this.$options.tagType,
          icon: 'tag',
          title: s__('Pipeline|Tag name'),
          unique: true,
          token: PipelineTagNameToken,
          operators: OPERATOR_IS_ONLY,
          projectId: this.projectId,
          disabled: this.selectedTypes.includes(this.$options.branchType),
        },
        {
          type: this.$options.statusType,
          icon: 'status',
          title: s__('Pipeline|Status'),
          unique: true,
          token: PipelineStatusToken,
          operators: OPERATOR_IS_ONLY,
        },
      ];
    },
    parsedParams() {
      return map(this.params, (val, key) => ({
        type: key,
        value: { data: val, operator: '=' },
      }));
    },
    value: {
      get() {
        return this.internalValue.length > 0 ? this.internalValue : this.parsedParams;
      },
      set(value) {
        this.internalValue = value;
      },
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
      v-model="value"
      :placeholder="__('Filter pipelines')"
      :available-tokens="tokens"
      @submit="onSubmit"
    />
  </div>
</template>

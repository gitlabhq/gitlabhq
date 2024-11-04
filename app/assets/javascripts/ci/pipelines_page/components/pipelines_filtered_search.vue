<script>
import { GlFilteredSearch } from '@gitlab/ui';
import { map } from 'lodash';
import { s__ } from '~/locale';
import Tracking from '~/tracking';
import { OPERATORS_IS } from '~/vue_shared/components/filtered_search_bar/constants';
import { TRACKING_CATEGORIES } from '../../constants';
import PipelineBranchNameToken from '../tokens/pipeline_branch_name_token.vue';
import PipelineSourceToken from '../tokens/pipeline_source_token.vue';
import PipelineStatusToken from '../tokens/pipeline_status_token.vue';
import PipelineTagNameToken from '../tokens/pipeline_tag_name_token.vue';
import PipelineTriggerAuthorToken from '../tokens/pipeline_trigger_author_token.vue';

export default {
  userType: 'username',
  branchType: 'ref',
  tagType: 'tag',
  statusType: 'status',
  sourceType: 'source',
  defaultTokensLength: 1,
  components: {
    GlFilteredSearch,
  },
  mixins: [Tracking.mixin()],
  inject: ['defaultBranchName', 'projectId'],
  props: {
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
          operators: OPERATORS_IS,
          projectId: this.projectId,
        },
        {
          type: this.$options.branchType,
          icon: 'branch',
          title: s__('Pipeline|Branch name'),
          unique: true,
          token: PipelineBranchNameToken,
          operators: OPERATORS_IS,
          projectId: this.projectId,
          defaultBranchName: this.defaultBranchName,
          disabled: this.selectedTypes.includes(this.$options.tagType),
        },
        {
          type: this.$options.tagType,
          icon: 'tag',
          title: s__('Pipeline|Tag name'),
          unique: true,
          token: PipelineTagNameToken,
          operators: OPERATORS_IS,
          projectId: this.projectId,
          disabled: this.selectedTypes.includes(this.$options.branchType),
        },
        {
          type: this.$options.statusType,
          icon: 'status',
          title: s__('Pipeline|Status'),
          unique: true,
          token: PipelineStatusToken,
          operators: OPERATORS_IS,
        },
        {
          type: this.$options.sourceType,
          icon: 'trigger-source',
          title: s__('Pipeline|Source'),
          unique: true,
          token: PipelineSourceToken,
          operators: OPERATORS_IS,
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
      this.track('click_filtered_search', { label: TRACKING_CATEGORIES.search });
      this.$emit('filterPipelines', filters);
    },
  },
};
</script>

<template>
  <gl-filtered-search
    v-model="value"
    :placeholder="__('Filter pipelines')"
    :available-tokens="tokens"
    @submit="onSubmit"
  />
</template>

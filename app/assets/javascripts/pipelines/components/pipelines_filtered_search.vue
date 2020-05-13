<script>
import { GlFilteredSearch } from '@gitlab/ui';
import { __, s__ } from '~/locale';
import PipelineTriggerAuthorToken from './tokens/pipeline_trigger_author_token.vue';
import PipelineBranchNameToken from './tokens/pipeline_branch_name_token.vue';
import Api from '~/api';
import createFlash from '~/flash';
import { FETCH_AUTHOR_ERROR_MESSAGE, FETCH_BRANCH_ERROR_MESSAGE } from '../constants';

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
  },
  data() {
    return {
      projectUsers: null,
      projectBranches: null,
    };
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
          triggerAuthors: this.projectUsers,
          projectId: this.projectId,
        },
        {
          type: 'ref',
          icon: 'branch',
          title: s__('Pipeline|Branch name'),
          unique: true,
          token: PipelineBranchNameToken,
          operators: [{ value: '=', description: __('is'), default: 'true' }],
          branches: this.projectBranches,
          projectId: this.projectId,
        },
      ];
    },
  },
  created() {
    Api.projectUsers(this.projectId)
      .then(users => {
        this.projectUsers = users;
      })
      .catch(err => {
        createFlash(FETCH_AUTHOR_ERROR_MESSAGE);
        throw err;
      });

    Api.branches(this.projectId)
      .then(({ data }) => {
        this.projectBranches = data.map(branch => branch.name);
      })
      .catch(err => {
        createFlash(FETCH_BRANCH_ERROR_MESSAGE);
        throw err;
      });
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
      @submit="onSubmit"
    />
  </div>
</template>

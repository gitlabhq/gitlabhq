<script>
import { GlFilteredSearch } from '@gitlab/ui';
import { __, s__ } from '~/locale';
import PipelineTriggerAuthorToken from './tokens/pipeline_trigger_author_token.vue';
import Api from '~/api';
import createFlash from '~/flash';

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
    };
  },
  computed: {
    tokens() {
      return [
        {
          type: 'username',
          icon: 'user',
          title: s__('Pipeline|Trigger author'),
          dataType: 'username',
          unique: true,
          token: PipelineTriggerAuthorToken,
          operators: [{ value: '=', description: __('is'), default: 'true' }],
          triggerAuthors: this.projectUsers,
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
        createFlash(__('There was a problem fetching project users.'));
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

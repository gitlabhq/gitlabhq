<script>
  import { timeIntervalInWords } from '../../lib/utils/datetime_utility.js';
  import clipboardButton from '../../vue_shared/components/clipboard_button.vue';
  import iconCommit from 'icons/_icon_commit.svg';

  export default {
    name: 'pipelineInfoBlock',

    props: {
      pipeline: {
        type: Object,
        required: true,
      },
    },

    components: {
      clipboardButton,
    },

    data() {
      return {
        isLongCommitHashHidden: true,
        iconCommit,
      };
    },

    computed: {
      pluralizeJob() {
        // return gl.pluralize('job')
        return '80 jobs';
      },
      pipelineDuration() {
        return timeIntervalInWords(this.pipeline.details.duration);
      },
      queuedDuration() {
        return timeIntervalInWords(this.pipeline.details.queued);
      }
    },

    methods: {
      expandCommitSha(){
        this.isLongCommitHashHidden = !this.isLongCommitHashHidden;
      },
    }
  };
</script>
<template>
  <div class="info-well">
    <div class="well-segment pipeline-info">
      <div class="icon-container">
        <i class="fa fa-clock-o" aria-hidden="true"></i>
      </div>
      {{pluralizeJob}}

      <template v-if="pipeline.ref">
        from
        <a
          :href="pipeline.ref.path"
          class="ref-name">
          {{pipeline.ref.name}}
        </a>
      </template>

      <template v-if="pipeline.details.duration">
        in {{pipelineDuration}}
      </template>
      <template v-if="pipeline.details.queued">
        (queued for {{queuedDuration}})
      </template>
    </div>

    <div class="well-segment branch-info">
      <div class="icon-container commit-icon" v-html="iconCommit"></div>

      <a
        v-show="isLongCommitHashHidden"
        :href="pipeline.commit.commit_path"
        class="commit-sha">
        {{pipeline.commit.short_id}}
      </a>

       <a
        v-show="!isLongCommitHashHidden"
        :href="pipeline.commit.commit_path"
        class="commit-sha commit-hash-full">
        {{pipeline.commit.id}}
      </a>
      <button
        type="button"
        class="btn-transparent btn-blank hidden-xs hidden-sm"
        @click.prevent="expandCommitSha">
        <span class="text-expander">
          ...
        </span>
      </button>
      <clipboard-button
        title="Copy commit SHA to clipboard"
        :text="pipeline.commit.id"
        />
    </div>
  </div>
</template>

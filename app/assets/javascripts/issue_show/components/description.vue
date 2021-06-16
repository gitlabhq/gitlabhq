<script>
import { GlSafeHtmlDirective as SafeHtml } from '@gitlab/ui';
import $ from 'jquery';
import createFlash from '~/flash';
import { s__, sprintf } from '~/locale';
import TaskList from '../../task_list';
import animateMixin from '../mixins/animate';

export default {
  directives: {
    SafeHtml,
  },

  mixins: [animateMixin],

  props: {
    canUpdate: {
      type: Boolean,
      required: true,
    },
    descriptionHtml: {
      type: String,
      required: true,
    },
    descriptionText: {
      type: String,
      required: false,
      default: '',
    },
    taskStatus: {
      type: String,
      required: false,
      default: '',
    },
    issuableType: {
      type: String,
      required: false,
      default: 'issue',
    },
    updateUrl: {
      type: String,
      required: false,
      default: null,
    },
    lockVersion: {
      type: Number,
      required: false,
      default: 0,
    },
  },
  data() {
    return {
      preAnimation: false,
      pulseAnimation: false,
      initialUpdate: true,
    };
  },
  watch: {
    descriptionHtml(newDescription, oldDescription) {
      if (!this.initialUpdate && newDescription !== oldDescription) {
        this.animateChange();
      } else {
        this.initialUpdate = false;
      }

      this.$nextTick(() => {
        this.renderGFM();
      });
    },
    taskStatus() {
      this.updateTaskStatusText();
    },
  },
  mounted() {
    this.renderGFM();
    this.updateTaskStatusText();
  },
  methods: {
    renderGFM() {
      $(this.$refs['gfm-content']).renderGFM();

      if (this.canUpdate) {
        // eslint-disable-next-line no-new
        new TaskList({
          dataType: this.issuableType,
          fieldName: 'description',
          lockVersion: this.lockVersion,
          selector: '.detail-page-description',
          onError: this.taskListUpdateError.bind(this),
        });
      }
    },

    taskListUpdateError() {
      createFlash({
        message: sprintf(
          s__(
            'Someone edited this %{issueType} at the same time you did. The description has been updated and you will need to make your changes again.',
          ),
          {
            issueType: this.issuableType,
          },
        ),
      });

      this.$emit('taskListUpdateFailed');
    },

    updateTaskStatusText() {
      const taskRegexMatches = this.taskStatus.match(/(\d+) of ((?!0)\d+)/);
      const $issuableHeader = $('.issuable-meta');
      const $tasks = $('#task_status', $issuableHeader);
      const $tasksShort = $('#task_status_short', $issuableHeader);

      if (taskRegexMatches) {
        $tasks.text(this.taskStatus);
        $tasksShort.text(
          `${taskRegexMatches[1]}/${taskRegexMatches[2]} task${taskRegexMatches[2] > 1 ? 's' : ''}`,
        );
      } else {
        $tasks.text('');
        $tasksShort.text('');
      }
    },
  },
};
</script>

<template>
  <div
    v-if="descriptionHtml"
    :class="{
      'js-task-list-container': canUpdate,
    }"
    class="description"
  >
    <div
      ref="gfm-content"
      v-safe-html="descriptionHtml"
      :class="{
        'issue-realtime-pre-pulse': preAnimation,
        'issue-realtime-trigger-pulse': pulseAnimation,
      }"
      class="md"
    ></div>
    <!-- eslint-disable vue/no-mutating-props -->
    <textarea
      v-if="descriptionText"
      ref="textarea"
      v-model="descriptionText"
      :data-update-url="updateUrl"
      class="hidden js-task-list-field"
      dir="auto"
    >
    </textarea>
    <!-- eslint-enable vue/no-mutating-props -->
  </div>
</template>

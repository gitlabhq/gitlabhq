<script>
import $ from 'jquery';
import { s__, sprintf } from '~/locale';
import createFlash from '~/flash';
import animateMixin from '../mixins/animate';
import TaskList from '../../task_list';
import recaptchaModalImplementor from '../../vue_shared/mixins/recaptcha_modal_implementor';

export default {
  mixins: [animateMixin, recaptchaModalImplementor],

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
      required: true,
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
    };
  },
  watch: {
    descriptionHtml() {
      this.animateChange();

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
          onSuccess: this.taskListUpdateSuccess.bind(this),
          onError: this.taskListUpdateError.bind(this),
        });
      }
    },

    taskListUpdateSuccess(data) {
      try {
        this.checkForSpam(data);
        this.closeRecaptcha();
      } catch (error) {
        if (error && error.name === 'SpamError') this.openRecaptcha();
      }
    },

    taskListUpdateError() {
      createFlash(
        sprintf(
          s__(
            'Someone edited this %{issueType} at the same time you did. The description has been updated and you will need to make your changes again.',
          ),
          {
            issueType: this.issuableType,
          },
        ),
      );

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
      :class="{
        'issue-realtime-pre-pulse': preAnimation,
        'issue-realtime-trigger-pulse': pulseAnimation,
      }"
      class="md"
      v-html="descriptionHtml"
    ></div>
    <textarea
      v-if="descriptionText"
      ref="textarea"
      v-model="descriptionText"
      :data-update-url="updateUrl"
      class="hidden js-task-list-field"
      dir="auto"
    >
    </textarea>

    <recaptcha-modal v-show="showRecaptcha" :html="recaptchaHTML" @close="closeRecaptcha" />
  </div>
</template>

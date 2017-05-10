<script>
  import animateMixin from '../mixins/animate';

  export default {
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
        required: true,
      },
      updatedAt: {
        type: String,
        required: true,
      },
      taskStatus: {
        type: String,
        required: true,
      },
    },
    data() {
      return {
        preAnimation: false,
        pulseAnimation: false,
        timeAgoEl: $('.issue_edited_ago'),
      };
    },
    watch: {
      descriptionHtml() {
        this.animateChange();

        this.$nextTick(() => {
          const toolTipTime = gl.utils.formatDate(this.updatedAt);

          this.timeAgoEl.attr('datetime', this.updatedAt)
            .attr('title', toolTipTime)
            .tooltip('fixTitle');

          $(this.$refs['gfm-entry-content']).renderGFM();

          if (this.canUpdate) {
            // eslint-disable-next-line no-new
            new gl.TaskList({
              dataType: 'issue',
              fieldName: 'description',
              selector: '.detail-page-description',
            });
          }
        });
      },
      taskStatus() {
        const taskRegexMatches = this.taskStatus.match(/(\d+) of (\d+)/);
        const $issuableHeader = $('.issuable-meta');
        let $tasks = $('#task_status', $issuableHeader);
        let $tasksShort = $('#task_status_short', $issuableHeader);

        if (this.taskStatus.indexOf('0 of 0') >= 0 || this.taskStatus.trim() === '') {
          $tasks.remove();
          $tasksShort.remove();
        } else if (!$tasks.length && !$tasksShort.length) {
          $tasks = $issuableHeader.append('<span id="task_status" class="hidden-xs hidden-sm"></span>')
            .find('#task_status');
          $tasksShort = $issuableHeader.append('<span id="task_status_short" class="hidden-md hidden-lg"></span>')
            .find('#task_status_short');
        }

        if (taskRegexMatches) {
          $tasks.text(this.taskStatus);
          $tasksShort.text(`${taskRegexMatches[1]}/${taskRegexMatches[2]} task${taskRegexMatches[2] > 1 ? 's' : ''}`);
        }
      },
    },
  };
</script>

<template>
  <div
    v-if="descriptionHtml"
    class="description"
    :class="{
      'js-task-list-container': canUpdate
    }"
  >
    <div
      class="wiki"
      :class="{
        'issue-realtime-pre-pulse': preAnimation,
        'issue-realtime-trigger-pulse': pulseAnimation
      }"
      v-html="descriptionHtml"
      ref="gfm-content"
    >
    </div>
    <textarea
      class="hidden js-task-list-field"
      v-if="descriptionText"
    >{{ descriptionText }}</textarea>
  </div>
</template>

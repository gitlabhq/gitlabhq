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
        required: false,
        default: '',
      },
      taskStatus: {
        type: String,
        required: false,
        default: '',
      },
    },
    data() {
      return {
        preAnimation: false,
        pulseAnimation: false,
        timeAgoEl: $('.js-issue-edited-ago'),
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

          this.renderGFM();
        });
      },
      taskStatus() {
        const taskRegexMatches = this.taskStatus.match(/(\d+) of (\d+)/);
        const $issuableHeader = $('.issuable-meta');
        const $tasks = $('#task_status', $issuableHeader);
        const $tasksShort = $('#task_status_short', $issuableHeader);

        if (taskRegexMatches) {
          $tasks.text(this.taskStatus);
          $tasksShort.text(`${taskRegexMatches[1]}/${taskRegexMatches[2]} task${taskRegexMatches[2] > 1 ? 's' : ''}`);
        } else {
          $tasks.text('');
          $tasksShort.text('');
        }
      },
    },
    methods: {
      renderGFM() {
        $(this.$refs['gfm-entry-content']).renderGFM();

        if (this.canUpdate) {
          // eslint-disable-next-line no-new
          new gl.TaskList({
            dataType: 'issue',
            fieldName: 'description',
            selector: '.detail-page-description',
          });
        }
      },
    },
    mounted() {
      this.renderGFM();
    },
  };
</script>

<template>
  <div
    v-else-if="descriptionHtml"
    class="description"
    :class="{
      'js-task-list-container': canUpdate
    }">
    <div
      class="wiki"
      :class="{
        'issue-realtime-pre-pulse': preAnimation,
        'issue-realtime-trigger-pulse': pulseAnimation
      }"
      v-html="descriptionHtml"
      ref="gfm-content">
    </div>
    <textarea
      class="hidden js-task-list-field"
      v-if="descriptionText"
      v-model="descriptionText">
    </textarea>
  </div>
</template>

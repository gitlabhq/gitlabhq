<script>
  import animateMixin from '../mixins/animate';
  import TaskList from '../../task_list';

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
    methods: {
      renderGFM() {
        $(this.$refs['gfm-content']).renderGFM();

        if (this.canUpdate) {
          // eslint-disable-next-line no-new
          new TaskList({
            dataType: 'issue',
            fieldName: 'description',
            selector: '.detail-page-description',
          });
        }
      },
      updateTaskStatusText() {
        const taskRegexMatches = this.taskStatus.match(/(\d+) of ((?!0)\d+)/);
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
    mounted() {
      this.renderGFM();
      this.updateTaskStatusText();
    },
  };
</script>

<template>
  <div
    v-if="descriptionHtml"
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

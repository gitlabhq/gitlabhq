<script>
  import animateMixin from '../mixins/animate';
  import descriptionField from './fields/description.vue';

  export default {
    mixins: [animateMixin],
    props: {
      canUpdate: {
        type: Boolean,
        required: true,
      },
      store: {
        type: Object,
        required: true,
      },
      showForm: {
        type: Boolean,
        required: true,
      },
<<<<<<< HEAD
      markdownPreviewUrl: {
        type: String,
        required: true,
      },
      markdownDocs: {
=======
      taskStatus: {
>>>>>>> 07c984d... Port fix-realtime-edited-text-for-issues 9-2-stable fix to master.
        type: String,
        required: true,
      },
    },
    data() {
      return {
        state: this.store.state,
        preAnimation: false,
        pulseAnimation: false,
      };
    },
    computed: {
      descriptionHtml() {
        return this.state.descriptionHtml;
      },
      descriptionText() {
        return this.state.descriptionText;
      },
      updatedAt() {
        return this.state.updated_at;
      },
      taskStatus() {
        return this.state.taskStatus;
      },
    },
    watch: {
      descriptionHtml() {
        this.animateChange();

        this.$nextTick(() => {
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
    components: {
      descriptionField,
    },
    mounted() {
      this.renderGFM();
    },
  };
</script>

<template>
<<<<<<< HEAD
  <div :class="{ 'common-note-form': showForm }">
    <description-field
      v-if="showForm"
      :store="store"
      :markdown-preview-url="markdownPreviewUrl"
      :markdown-docs="markdownDocs" />
=======
  <div
    v-if="descriptionHtml"
    class="description"
    :class="{
      'js-task-list-container': canUpdate
    }">
>>>>>>> f53d703... Fixed else-if in description
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
  </div>
</template>

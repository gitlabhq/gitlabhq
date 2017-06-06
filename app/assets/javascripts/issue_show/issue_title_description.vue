<script>
import Visibility from 'visibilityjs';
import Poll from './../lib/utils/poll';
import Service from './services/index';
import tasks from './actions/tasks';
import edited from './components/edited.vue';
import normalizeNewlines from '../lib/utils/normalize_newlines';

export default {
  props: {
    endpoint: {
      required: true,
      type: String,
    },
    canUpdateTasksClass: {
      required: true,
      type: String,
    },
    isEdited: {
      type: Boolean,
      default: false,
      required: false,
    },
    initialTitle: {
      type: String,
      required: true,
    },
    initialDescription: {
      type: String,
      required: true,
    },
  },
  data() {
    const resource = new Service(this.$http, this.endpoint);

    const poll = new Poll({
      resource,
      method: 'getTitle',
      successCallback: (res) => {
        this.renderResponse(res);
      },
      errorCallback: (err) => {
        throw new Error(err);
      },
    });

    return {
      poll,
      apiData: {},
      tasks: '0 of 0',
      title: this.initialTitle,
      titleText: '',
      titleFlag: {
        pre: false,
        pulse: false,
      },
      description: this.initialDescription,
      descriptionText: '',
      descriptionChange: false,
      descriptionFlag: {
        pre: false,
        pulse: false,
      },
      titleEl: document.querySelector('title'),
      hasBeenEdited: this.isEdited,
    };
  },
  components: {
    edited,
  },
  methods: {
    updateFlag(key, toggle) {
      this[key].pre = toggle;
      this[key].pulse = !toggle;
    },
    renderResponse(res) {
      this.apiData = res.json();

      if (this.apiData.updated_at) this.hasBeenEdited = true;

      this.triggerAnimation();
    },
    updateTaskHTML() {
      tasks(this.apiData, this.tasks);
    },
    elementsToVisualize(noTitleChange, noDescriptionChange) {
      if (!noTitleChange) {
        this.setTabTitle();
        this.updateFlag('titleFlag', true);
      }

      if (!noDescriptionChange) {
        // only change to true when we need to bind TaskLists the html of description
        this.descriptionChange = true;
        this.updateTaskHTML();
        this.tasks = this.apiData.task_status;
        this.updateFlag('descriptionFlag', true);
      }
    },
    setTabTitle() {
      const currentTabTitleScope = this.titleEl.innerText.split('·');
      currentTabTitleScope[0] = `${this.titleText} (#${this.apiData.issue_number}) `;
      this.titleEl.innerText = currentTabTitleScope.join('·');
    },
    animate(title, description) {
      this.title = title;
      this.description = description;

      setTimeout(() => {
        this.updateFlag('titleFlag', false);
        this.updateFlag('descriptionFlag', false);
      });
    },
    triggerAnimation() {
      // always reset to false before checking the change
      this.descriptionChange = false;

      const { title, description } = this.apiData;
      this.descriptionText = this.apiData.description_text;
      this.titleText = this.apiData.title_text;

      const noTitleChange = this.title === title;
      const noDescriptionChange =
        normalizeNewlines(this.description) === normalizeNewlines(description);

      /**
      * since opacity is changed, even if there is no diff for Vue to update
      * we must check the title/description even on a 304 to ensure no visual change
      */
      if (noTitleChange && noDescriptionChange) return;

      this.elementsToVisualize(noTitleChange, noDescriptionChange);
      this.animate(title, description);
    },
  },
  created() {
    if (!Visibility.hidden()) {
      this.poll.makeRequest();
    }

    Visibility.change(() => {
      if (!Visibility.hidden()) {
        this.poll.restart();
      } else {
        this.poll.stop();
      }
    });
  },
  updated() {
    // if new html is injected (description changed) - bind TaskList and call renderGFM
    if (this.descriptionChange) {
      $(this.$refs['issue-content-container-gfm-entry']).renderGFM();

      const tl = new gl.TaskList({
        dataType: 'issue',
        fieldName: 'description',
        selector: '.detail-page-description',
      });

      return tl && null;
    }

    return null;
  },
};
</script>

<template>
  <div>
    <h2
      class="title"
      :class="{ 'issue-realtime-pre-pulse': titleFlag.pre, 'issue-realtime-trigger-pulse': titleFlag.pulse }"
      ref="issue-title"
      v-html="title"
    >
    </h2>
    <div
      class="description is-task-list-enabled"
      :class="canUpdateTasksClass"
      v-if="description"
    >
      <div
        class="wiki"
        :class="{ 'issue-realtime-pre-pulse': descriptionFlag.pre, 'issue-realtime-trigger-pulse': descriptionFlag.pulse }"
        v-html="description"
        ref="issue-content-container-gfm-entry"
      >
      </div>
      <textarea
        class="hidden js-task-list-field"
        v-if="descriptionText"
      >{{descriptionText}}</textarea>
    </div>
    <edited
      v-if="hasBeenEdited"
      :updated-at="apiData.updated_at"
      :updated-by-name="apiData.updated_by_name"
      :updated-by-path="apiData.updated_by_path"
    />
  </div>
</template>

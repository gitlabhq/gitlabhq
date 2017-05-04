<script>
import Visibility from 'visibilityjs';
import Poll from './../lib/utils/poll';
import Service from './services/index';
import tasks from './actions/tasks';

export default {
  props: {
    endpoint: {
      required: true,
      type: String,
    },
    canUpdateIssue: {
      required: true,
      type: String,
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

    const defaultFlags = {
      pre: true,
      pulse: false,
    };

    return {
      poll,
      apiData: {},
      tasks: '0 of 0',
      title: null,
      titleText: '',
      titleFlag: defaultFlags,
      description: null,
      descriptionText: '',
      descriptionChange: false,
      descriptionFlag: defaultFlags,
      timeAgoEl: $('.issue_edited_ago'),
      titleEl: document.querySelector('title'),
    };
  },
  methods: {
    renderResponse(res) {
      this.apiData = res.json();
      this.triggerAnimation();
    },
    updateTaskHTML() {
      tasks(this.apiData, this.tasks);
    },
    elementsToVisualize(noTitleChange, noDescriptionChange) {
      if (!noTitleChange) {
        this.titleText = this.apiData.title_text;
        this.titleFlag = { pre: true, pulse: false };
      }

      if (!noDescriptionChange) {
        // only change to true when we need to bind TaskLists the html of description
        this.descriptionChange = true;
        this.updateTaskHTML();
        this.tasks = this.apiData.task_status;
        this.descriptionFlag = { pre: true, pulse: false };
      }

      return { noTitleChange, noDescriptionChange };
    },
    setTabTitle() {
      const currentTabTitleScope = this.titleEl.innerText.split('·');
      currentTabTitleScope[0] = `${this.titleText} (#${this.apiData.issue_number}) `;
      this.titleEl.innerText = currentTabTitleScope.join('·');
    },
    animate(title, description) {
      this.title = title;
      this.description = description;
      this.setTabTitle();

      this.$nextTick(() => {
        this.titleFlag = { pre: false, pulse: true };
        this.descriptionFlag = { pre: false, pulse: true };
      });
    },
    triggerAnimation() {
      // always reset to false before checking the change
      this.descriptionChange = false;

      const { title, description } = this.apiData;
      this.descriptionText = this.apiData.description_text;

      const noTitleChange = this.title === title;
      const noDescriptionChange = this.description === description;

      /**
      * since opacity is changed, even if there is no diff for Vue to update
      * we must check the title/description even on a 304 to ensure no visual change
      */
      if (noTitleChange && noDescriptionChange) return;

      this.elementsToVisualize(noTitleChange, noDescriptionChange);
      this.animate(title, description);
    },
    updateEditedTimeAgo() {
      const toolTipTime = gl.utils.formatDate(this.apiData.updated_at);

      this.timeAgoEl.attr('datetime', this.apiData.updated_at);
      this.timeAgoEl.attr('data-original-title', toolTipTime);
    },
  },
  computed: {
    descriptionClass() {
      return `description ${this.canUpdateIssue} is-task-list-enabled`;
    },
    titleAnimationCss() {
      return {
        'title issue-realtime-pre-pulse': this.titleFlag.pre,
        'title issue-realtime-trigger-pulse': this.titleFlag.pulse,
      };
    },
    descriptionAnimationCss() {
      return {
        'wiki issue-realtime-pre-pulse': this.descriptionFlag.pre,
        'wiki issue-realtime-trigger-pulse': this.descriptionFlag.pulse,
      };
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
      this.updateEditedTimeAgo();

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
      :class="titleAnimationCss"
      ref="issue-title"
      v-html="title"
    >
    </h2>
    <div
      :class="descriptionClass"
      v-if="description"
    >
      <div
        :class="descriptionAnimationCss"
        v-html="description"
        ref="issue-content-container-gfm-entry"
      >
      </div>
      <textarea
        class="hidden js-task-list-field"
        v-if="descriptionText"
      >{{descriptionText}}</textarea>
    </div>
  </div>
</template>

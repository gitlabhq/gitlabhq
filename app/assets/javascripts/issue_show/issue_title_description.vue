<script>
import Visibility from 'visibilityjs';
import Poll from './../lib/utils/poll';
import Service from './services/index';
import tasks from './actions/tasks';

export default {
  props: {
    endpoint: { required: true, type: String },
    candescription: { required: true, type: String },
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
        if (process.env.NODE_ENV !== 'production') {
          // eslint-disable-next-line no-console
          console.error('ISSUE SHOW REALTIME ERROR', err, err.stack);
        } else {
          throw new Error(err);
        }
      },
    });

    return {
      poll,
      apiData: {},
      timeoutId: null,
      title: '<span></span>',
      titleText: '',
      description: '<span></span>',
      descriptionText: '',
      descriptionChange: false,
      tasks: '0 of 0',
    };
  },
  methods: {
    renderResponse(res) {
      this.apiData = JSON.parse(res.body);
      this.triggerAnimation();
    },
    updateTaskHTML() {
      tasks(this.apiData, this.tasks);
    },
    elementsToVisualize(noTitleChange, noDescriptionChange) {
      const elementStack = [];

      if (!noTitleChange) {
        this.titleText = this.apiData.title_text;
        elementStack.push(this.$el.querySelector('.title'));
      }

      if (!noDescriptionChange) {
        // only change to true when we need to bind TaskLists the html of description
        this.descriptionChange = true;
        this.updateTaskHTML();
        this.tasks = this.apiData.task_status;
        elementStack.push(this.$el.querySelector('.wiki'));
      }

      elementStack.forEach((element) => {
        element.classList.remove('issue-realtime-trigger-pulse');
        element.classList.add('issue-realtime-pre-pulse');
      });

      return elementStack;
    },
    setTabTitle() {
      const currentTabTitle = document.querySelector('title');
      const currentTabTitleScope = currentTabTitle.innerText.split('·');
      currentTabTitleScope[0] = `${this.titleText} (#${this.apiData.issue_number}) `;
      currentTabTitle.innerText = currentTabTitleScope.join('·');
    },
    animate(title, description, elementsToVisualize) {
      this.timeoutId = setTimeout(() => {
        this.title = title;
        this.description = description;
        this.setTabTitle();

        elementsToVisualize.forEach((element) => {
          element.classList.remove('issue-realtime-pre-pulse');
          element.classList.add('issue-realtime-trigger-pulse');
        });

        clearTimeout(this.timeoutId);
      }, 0);
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

      const elementsToVisualize = this.elementsToVisualize(
        noTitleChange,
        noDescriptionChange,
      );

      this.animate(title, description, elementsToVisualize);
    },
    updateEditedTimeAgo() {
      const toolTipTime = gl.utils.formatDate(this.apiData.updated_at);
      const $timeAgoNode = $('.issue_edited_ago');

      $timeAgoNode.attr('datetime', this.apiData.updated_at);
      $timeAgoNode.attr('data-original-title', toolTipTime);
    },
  },
  computed: {
    descriptionClass() {
      return `description ${this.candescription} is-task-list-enabled`;
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
    <h2 class="title issue-realtime-trigger-pulse" v-html="title"></h2>
    <div
      :class="descriptionClass"
      v-if="description"
    >
      <div
        class="wiki issue-realtime-trigger-pulse"
        v-html="description"
        ref="issue-content-container-gfm-entry"
      >
      </div>
      <textarea class="hidden js-task-list-field" v-if="descriptionText">{{descriptionText}}</textarea>
    </div>
  </div>
</template>

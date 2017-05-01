<script>
import Visibility from 'visibilityjs';
import Poll from './../lib/utils/poll';
import Service from './services/index';

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
          console.error('ISSUE SHOW REALTIME ERROR', err);
        } else {
          throw new Error(err);
        }
      },
    });

    return {
      poll,
      timeoutId: null,
      title: '<span></span>',
      titleText: '',
      description: '<span></span>',
      descriptionText: '',
      descriptionChange: false,
      taskStatus: '',
    };
  },
  methods: {
    renderResponse(res) {
      const data = JSON.parse(res.body);
      this.issueIID = data.issue_number;
      this.triggerAnimation(data);
    },
    updateTaskHTML(data) {
      this.taskStatus = data.task_status;
      document.querySelector('#task_status').innerText = this.taskStatus;
    },
    elementsToVisualize(noTitleChange, noDescriptionChange, data) {
      const elementStack = [];

      if (!noTitleChange) {
        this.titleText = data.title_text;
        elementStack.push(this.$el.querySelector('.title'));
      }

      if (!noDescriptionChange) {
        // only change to true when we need to bind TaskLists the html of description
        this.descriptionChange = true;
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
      currentTabTitleScope[0] = `${this.titleText} (#${this.issueIID}) `;
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
    triggerAnimation(data) {
      // always reset to false before checking the change
      this.descriptionChange = false;

      const { title, description } = data;
      this.descriptionText = data.description_text;
      this.updateTaskHTML(data);
      /**
      * since opacity is changed, even if there is no diff for Vue to update
      * we must check the title/description even on a 304 to ensure no visual change
      */
      const noTitleChange = this.title === title;
      const noDescriptionChange = this.description === description;

      if (noTitleChange && noDescriptionChange) return;

      const elementsToVisualize = this.elementsToVisualize(
        noTitleChange,
        noDescriptionChange,
        data,
      );

      this.animate(title, description, elementsToVisualize);
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
      const tl = new gl.TaskList({
        dataType: 'issue',
        fieldName: 'description',
        selector: '.detail-page-description',
      });

      $(this.$refs['issue-content-container-gfm-entry']).renderGFM();
      return tl;
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

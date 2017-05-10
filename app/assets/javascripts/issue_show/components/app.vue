<script>
import Visibility from 'visibilityjs';
import Poll from '../../lib/utils/poll';
import Service from '../services/index';
import Store from '../stores';
import titleComponent from './title.vue';
import descriptionComponent from './description.vue';

export default {
  props: {
    endpoint: {
      required: true,
      type: String,
    },
    canUpdate: {
      required: true,
      type: Boolean,
    },
    issuableRef: {
      type: String,
      required: true,
    },
    initialTitle: {
      type: String,
      required: true,
    },
    initialDescriptionHtml: {
      type: String,
      required: false,
      default: '',
    },
    initialDescriptionText: {
      type: String,
      required: false,
      default: '',
    },
  },
  data() {
    const store = new Store({
      title: this.initialTitle,
      descriptionHtml: this.initialDescriptionHtml,
      descriptionText: this.initialDescriptionText,
    });

    return {
      store,
      state: store.state,
    };
  },
  components: {
    descriptionComponent,
    titleComponent,
  },
  created() {
    const resource = new Service(this.endpoint);
    const poll = new Poll({
      resource,
      method: 'getData',
      successCallback: (res) => {
        this.store.updateState(res.json());
      },
      errorCallback(err) {
        throw new Error(err);
      },
    });

    if (!Visibility.hidden()) {
      poll.makeRequest();
    }

    Visibility.change(() => {
      if (!Visibility.hidden()) {
        poll.restart();
      } else {
        poll.stop();
      }
    });
  },
};
</script>

<template>
  <div>
    <title-component
      :issuable-ref="issuableRef"
      :title-html="state.titleHtml"
      :title-text="state.titleText" />
    <description-component
      :can-update="canUpdate"
      :description-html="state.descriptionHtml"
      :description-text="state.descriptionText"
      :updated-at="state.updatedAt"
      :task-status="state.taskStatus" />
  </div>
</template>

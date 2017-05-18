<script>
import Visibility from 'visibilityjs';
import Poll from '../../lib/utils/poll';
import Service from '../services/index';
import Store from '../stores';
import titleComponent from './title.vue';
import descriptionComponent from './description.vue';
import editedComponent from './edited.vue';

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
    updatedAt: {
      type: String,
      required: false,
      default: '',
    },
    updatedByName: {
      type: String,
      required: false,
      default: '',
    },
    updatedByPath: {
      type: String,
      required: false,
      default: '',
    },
  },
  data() {
    const store = new Store({
      titleHtml: this.initialTitle,
      descriptionHtml: this.initialDescriptionHtml,
      descriptionText: this.initialDescriptionText,
      updatedAt: this.updatedAt,
      updatedByName: this.updatedByName,
      updatedByPath: this.updatedByPath,
    });

    return {
      store,
      state: store.state,
    };
  },
  components: {
    descriptionComponent,
    titleComponent,
    editedComponent,
  },
  computed: {
    hasUpdated() {
      return !!this.state.updatedAt;
    },
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
      v-if="state.descriptionHtml"
      :can-update="canUpdate"
      :description-html="state.descriptionHtml"
      :description-text="state.descriptionText"
      :task-status="state.taskStatus" />
    <edited-component
      v-if="hasUpdated"
      :updated-at="state.updatedAt"
      :updated-by-name="state.updatedByName"
      :updated-by-path="state.updatedByPath"
    />
  </div>
</template>

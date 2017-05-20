<script>
import VisibilitySocketManager from '../../lib/utils/socket/visibility_socket_manager';
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
      titleHtml: this.initialTitle,
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
    VisibilitySocketManager.subscribe(this.endpoint, null, {
      updateCallback: (response) => {
        this.store.updateState(response.json());
      },
      errorCallback(error) {
        throw new Error(error);
      },
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
      :updated-at="state.updatedAt"
      :task-status="state.taskStatus" />
  </div>
</template>

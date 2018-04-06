import Visibility from 'visibilityjs';
import { __ } from '../../locale';
import Flash from '../../flash';
import Poll from '../../lib/utils/poll';
import EmptyState from '../components/empty_state.vue';
import SvgBlankState from '../components/blank_state.vue';
import LoadingIcon from '../../vue_shared/components/loading_icon.vue';
import PipelinesTableComponent from '../components/pipelines_table.vue';
import eventHub from '../event_hub';

export default {
  components: {
    PipelinesTableComponent,
    SvgBlankState,
    EmptyState,
    LoadingIcon,
  },
  data() {
    return {
      isLoading: false,
      hasError: false,
      isMakingRequest: false,
      updateGraphDropdown: false,
      hasMadeRequest: false,
    };
  },
  beforeMount() {
    this.poll = new Poll({
      resource: this.service,
      method: 'getPipelines',
      data: this.requestData ? this.requestData : undefined,
      successCallback: this.successCallback,
      errorCallback: this.errorCallback,
      notificationCallback: this.setIsMakingRequest,
    });

    if (!Visibility.hidden()) {
      this.isLoading = true;
      this.poll.makeRequest();
    } else {
      // If tab is not visible we need to make the first request so we don't show the empty
      // state without knowing if there are any pipelines
      this.fetchPipelines();
    }

    Visibility.change(() => {
      if (!Visibility.hidden()) {
        this.poll.restart();
      } else {
        this.poll.stop();
      }
    });

    eventHub.$on('postAction', this.postAction);
  },
  beforeDestroy() {
    eventHub.$off('postAction', this.postAction);
  },
  destroyed() {
    this.poll.stop();
  },
  methods: {
    fetchPipelines() {
      if (!this.isMakingRequest) {
        this.isLoading = true;

        this.service.getPipelines(this.requestData)
          .then(response => this.successCallback(response))
          .catch(() => this.errorCallback());
      }
    },
    setCommonData(pipelines) {
      this.store.storePipelines(pipelines);
      this.isLoading = false;
      this.updateGraphDropdown = true;
      this.hasMadeRequest = true;
    },
    errorCallback() {
      this.hasError = true;
      this.isLoading = false;
      this.updateGraphDropdown = false;
      this.hasMadeRequest = true;
    },
    setIsMakingRequest(isMakingRequest) {
      this.isMakingRequest = isMakingRequest;

      if (isMakingRequest) {
        this.updateGraphDropdown = false;
      }
    },
    postAction(endpoint) {
      this.service.postAction(endpoint)
        .then(() => this.fetchPipelines())
        .catch(() => Flash(__('An error occurred while making the request.')));
    },
  },
};

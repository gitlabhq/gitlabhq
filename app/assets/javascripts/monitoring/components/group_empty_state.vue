<script>
import { __, sprintf } from '~/locale';
import { GlEmptyState } from '@gitlab/ui';
import { metricStates } from '../constants';

export default {
  components: {
    GlEmptyState,
  },
  props: {
    documentationPath: {
      type: String,
      required: true,
    },
    settingsPath: {
      type: String,
      required: true,
    },
    selectedState: {
      type: String,
      required: true,
    },
    svgPath: {
      type: String,
      required: true,
    },
  },
  data() {
    const documentationLink = `<a href="${this.documentationPath}">${__('More information')}</a>`;
    return {
      states: {
        [metricStates.NO_DATA]: {
          title: __('No data to display'),
          slottedDescription: sprintf(
            __(
              'The data source is connected, but there is no data to display. %{documentationLink}',
            ),
            { documentationLink },
            false,
          ),
        },
        [metricStates.TIMEOUT]: {
          title: __('Connection timed out'),
          slottedDescription: sprintf(
            __(
              "Charts can't be displayed as the request for data has timed out. %{documentationLink}",
            ),
            { documentationLink },
            false,
          ),
        },
        [metricStates.CONNECTION_FAILED]: {
          title: __('Connection failed'),
          description: __(`We couldn't reach the Prometheus server.
            Either the server no longer exists or the configuration details need updating.`),
          buttonText: __('Verify configuration'),
          buttonPath: this.settingsPath,
        },
        [metricStates.BAD_QUERY]: {
          title: __('Query cannot be processed'),
          slottedDescription: sprintf(
            __(
              `The Prometheus server responded with "bad request".
              Please check your queries are correct and are supported in your Prometheus version. %{documentationLink}`,
            ),
            { documentationLink },
            false,
          ),
          buttonText: __('Verify configuration'),
          buttonPath: this.settingsPath,
        },
        [metricStates.LOADING]: {
          title: __('Waiting for performance data'),
          description: __(`Creating graphs uses the data from the Prometheus server.
            If this takes a long time, ensure that data is available.`),
        },
        [metricStates.UNKNOWN_ERROR]: {
          title: __('An error has occurred'),
          description: __('An error occurred while loading the data. Please try again.'),
        },
      },
    };
  },
  computed: {
    currentState() {
      return this.states[this.selectedState] || this.states[metricStates.UNKNOWN_ERROR];
    },
  },
};
</script>

<template>
  <gl-empty-state
    :title="currentState.title"
    :primary-button-text="currentState.buttonText"
    :primary-button-link="currentState.buttonPath"
    :description="currentState.description"
    :svg-path="svgPath"
    :compact="true"
  >
    <template v-if="currentState.slottedDescription" #description>
      <div v-html="currentState.slottedDescription"></div>
    </template>
  </gl-empty-state>
</template>

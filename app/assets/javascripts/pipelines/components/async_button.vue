<script>
  /* eslint-disable no-alert */

  import eventHub from '../event_hub';
  import loadingIcon from '../../vue_shared/components/loading_icon.vue';
  import icon from '../../vue_shared/components/icon.vue';
  import tooltip from '../../vue_shared/directives/tooltip';

  export default {
    directives: {
      tooltip,
    },
    components: {
      loadingIcon,
      icon,
    },
    props: {
      endpoint: {
        type: String,
        required: true,
      },
      title: {
        type: String,
        required: true,
      },
      icon: {
        type: String,
        required: true,
      },
      cssClass: {
        type: String,
        required: true,
      },
      pipelineId: {
        type: Number,
        required: true,
      },
      type: {
        type: String,
        required: true,
      },
    },
    data() {
      return {
        isLoading: false,
      };
    },
    computed: {
      buttonClass() {
        return `btn ${this.cssClass}`;
      },
    },
    created() {
      // We're using eventHub to listen to the modal here instead of
      // using props because it would would make the parent components
      // much more complex to keep track of the loading state of each button
      eventHub.$on('postAction', this.setLoading);
    },
    beforeDestroy() {
      eventHub.$off('postAction', this.setLoading);
    },
    methods: {
      onClick() {
        eventHub.$emit('openConfirmationModal', {
          pipelineId: this.pipelineId,
          endpoint: this.endpoint,
          type: this.type,
        });
      },
      setLoading(endpoint) {
        if (endpoint === this.endpoint) {
          this.isLoading = true;
        }
      },
    },
  };
</script>

<template>
  <button
    v-tooltip
    type="button"
    @click="onClick"
    :class="buttonClass"
    :title="title"
    :aria-label="title"
    data-container="body"
    data-placement="top"
    :disabled="isLoading">
    <icon
      :name="icon"
    />
    <loading-icon v-if="isLoading" />
  </button>
</template>

<script>
import Icon from '~/vue_shared/components/icon.vue';
import LoadingIcon from '~/vue_shared/components/loading_icon.vue';
import Tooltip from '~/vue_shared/directives/tooltip';

export default {
  name: 'Badge',
  components: {
    Icon,
    LoadingIcon,
    Tooltip,
  },
  directives: {
    Tooltip,
  },
  props: {
    imageUrl: {
      type: String,
      required: true,
    },
    linkUrl: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      hasError: false,
      isLoading: true,
      numRetries: 0,
    };
  },
  computed: {
    imageUrlWithRetries() {
      if (this.numRetries === 0) {
        return this.imageUrl;
      }

      return `${this.imageUrl}#retries=${this.numRetries}`;
    },
  },
  watch: {
    imageUrl() {
      this.hasError = false;
      this.isLoading = true;
      this.numRetries = 0;
    },
  },
  methods: {
    onError() {
      this.isLoading = false;
      this.hasError = true;
    },
    onLoad() {
      this.isLoading = false;
    },
    reloadImage() {
      this.hasError = false;
      this.isLoading = true;
      this.numRetries += 1;
    },
  },
};
</script>

<template>
  <div>
    <a
      v-show="!isLoading && !hasError"
      :href="linkUrl"
      target="_blank"
      rel="noopener noreferrer"
    >
      <img
        class="project-badge"
        :src="imageUrlWithRetries"
        @load="onLoad"
        @error="onError"
        aria-hidden="true"
      />
    </a>

    <loading-icon
      v-show="isLoading"
      :inline="true"
    />

    <div
      v-show="hasError"
      class="btn-group"
    >
      <div class="btn btn-default btn-sm disabled">
        <icon
          class="prepend-left-8 append-right-8"
          name="doc_image"
          :size="16"
          aria-hidden="true"
        />
      </div>
      <div
        class="btn btn-default btn-sm disabled"
      >
        <span class="prepend-left-8 append-right-8">{{ s__('Badges|No badge image') }}</span>
      </div>
    </div>

    <button
      v-show="hasError"
      class="btn btn-transparent btn-sm text-primary"
      type="button"
      v-tooltip
      :title="s__('Badges|Reload badge image')"
      @click="reloadImage"
    >
      <icon
        name="retry"
        :size="16"
      />
    </button>
  </div>
</template>

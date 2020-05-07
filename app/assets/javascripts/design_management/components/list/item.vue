<script>
import { GlLoadingIcon, GlIcon, GlIntersectionObserver } from '@gitlab/ui';
import Icon from '~/vue_shared/components/icon.vue';
import Timeago from '~/vue_shared/components/time_ago_tooltip.vue';
import { n__, __ } from '~/locale';
import { DESIGN_ROUTE_NAME } from '../../router/constants';

export default {
  components: {
    GlLoadingIcon,
    GlIntersectionObserver,
    GlIcon,
    Icon,
    Timeago,
  },
  props: {
    id: {
      type: [Number, String],
      required: true,
    },
    event: {
      type: String,
      required: true,
    },
    notesCount: {
      type: Number,
      required: true,
    },
    image: {
      type: String,
      required: true,
    },
    filename: {
      type: String,
      required: true,
    },
    updatedAt: {
      type: String,
      required: false,
      default: null,
    },
    isUploading: {
      type: Boolean,
      required: false,
      default: true,
    },
    imageV432x230: {
      type: String,
      required: false,
      default: null,
    },
  },
  data() {
    return {
      imageLoading: true,
      imageError: false,
      wasInView: false,
    };
  },
  computed: {
    icon() {
      const normalizedEvent = this.event.toLowerCase();
      const icons = {
        creation: {
          name: 'file-addition-solid',
          classes: 'text-success-500',
          tooltip: __('Added in this version'),
        },
        modification: {
          name: 'file-modified-solid',
          classes: 'text-primary-500',
          tooltip: __('Modified in this version'),
        },
        deletion: {
          name: 'file-deletion-solid',
          classes: 'text-danger-500',
          tooltip: __('Deleted in this version'),
        },
      };

      return icons[normalizedEvent] ? icons[normalizedEvent] : {};
    },
    notesLabel() {
      return n__('%d comment', '%d comments', this.notesCount);
    },
    imageLink() {
      return this.wasInView ? this.imageV432x230 || this.image : '';
    },
    showLoadingSpinner() {
      return this.imageLoading || this.isUploading;
    },
    showImageErrorIcon() {
      return this.wasInView && this.imageError;
    },
    showImage() {
      return !this.showLoadingSpinner && !this.showImageErrorIcon;
    },
  },
  methods: {
    onImageLoad() {
      this.imageLoading = false;
      this.imageError = false;
    },
    onImageError() {
      this.imageLoading = false;
      this.imageError = true;
    },
    onAppear() {
      // do nothing if image has previously
      // been in view
      if (this.wasInView) {
        return;
      }

      this.wasInView = true;
      this.imageLoading = true;
    },
  },
  DESIGN_ROUTE_NAME,
};
</script>

<template>
  <router-link
    :to="{
      name: $options.DESIGN_ROUTE_NAME,
      params: { id: filename },
      query: $route.query,
    }"
    class="card cursor-pointer text-plain js-design-list-item design-list-item"
  >
    <div class="card-body p-0 d-flex-center overflow-hidden position-relative">
      <div v-if="icon.name" class="design-event position-absolute">
        <span :title="icon.tooltip" :aria-label="icon.tooltip">
          <icon :name="icon.name" :size="18" :class="icon.classes" />
        </span>
      </div>
      <gl-intersection-observer @appear="onAppear">
        <gl-loading-icon v-if="showLoadingSpinner" size="md" />
        <gl-icon
          v-else-if="showImageErrorIcon"
          name="media-broken"
          class="text-secondary"
          :size="32"
        />
        <img
          v-show="showImage"
          :src="imageLink"
          :alt="filename"
          class="block mx-auto mw-100 mh-100 design-img"
          data-qa-selector="design_image"
          @load="onImageLoad"
          @error="onImageError"
        />
      </gl-intersection-observer>
    </div>
    <div class="card-footer d-flex w-100">
      <div class="d-flex flex-column str-truncated-100">
        <span class="bold str-truncated-100" data-qa-selector="design_file_name">{{
          filename
        }}</span>
        <span v-if="updatedAt" class="str-truncated-100">
          {{ __('Updated') }} <timeago :time="updatedAt" tooltip-placement="bottom" />
        </span>
      </div>
      <div v-if="notesCount" class="ml-auto d-flex align-items-center text-secondary">
        <icon name="comments" class="ml-1" />
        <span :aria-label="notesLabel" class="ml-1">
          {{ notesCount }}
        </span>
      </div>
    </div>
  </router-link>
</template>

<script>
import { GlLoadingIcon, GlIcon, GlIntersectionObserver, GlTooltipDirective } from '@gitlab/ui';
import { n__, __ } from '~/locale';
import Timeago from '~/vue_shared/components/time_ago_tooltip.vue';
import { DESIGN_ROUTE_NAME } from '../../router/constants';

export default {
  components: {
    GlLoadingIcon,
    GlIntersectionObserver,
    GlIcon,
    Timeago,
  },
  directives: {
    GlTooltip: GlTooltipDirective,
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
          tooltip: __('Archived in this version'),
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
    class="card gl-cursor-pointer text-plain js-design-list-item design-list-item design-list-item-new"
  >
    <div
      class="card-body gl-p-0 gl-display-flex gl-align-items-center gl-justify-content-center gl-overflow-hidden gl-relative"
    >
      <div v-if="icon.name" data-testid="design-event" class="gl-top-5 gl-right-5 gl-absolute">
        <span :title="icon.tooltip" :aria-label="icon.tooltip">
          <gl-icon
            :name="icon.name"
            :size="16"
            :class="icon.classes"
            data-qa-selector="design_status_icon"
            :data-qa-status="icon.name"
          />
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
          class="gl-display-block gl-mx-auto gl-max-w-full gl-max-h-full design-img"
          data-qa-selector="design_image"
          :data-qa-filename="filename"
          :data-testid="`design-img-${id}`"
          @load="onImageLoad"
          @error="onImageError"
        />
      </gl-intersection-observer>
    </div>
    <div class="card-footer gl-display-flex gl-w-full">
      <div class="gl-display-flex gl-flex-direction-column str-truncated-100">
        <span
          v-gl-tooltip
          class="gl-font-weight-bold str-truncated-100"
          data-qa-selector="design_file_name"
          :data-testid="`design-img-filename-${id}`"
          :title="filename"
          >{{ filename }}</span
        >
        <span v-if="updatedAt" class="str-truncated-100">
          {{ __('Updated') }} <timeago :time="updatedAt" tooltip-placement="bottom" />
        </span>
      </div>
      <div
        v-if="notesCount"
        class="gl-ml-auto gl-display-flex gl-align-items-center gl-text-gray-500"
      >
        <gl-icon name="comments" class="gl-ml-2" />
        <span :aria-label="notesLabel" class="gl-ml-2">
          {{ notesCount }}
        </span>
      </div>
    </div>
  </router-link>
</template>

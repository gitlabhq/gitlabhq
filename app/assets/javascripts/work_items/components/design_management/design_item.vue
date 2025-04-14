<script>
import {
  GlCard,
  GlLoadingIcon,
  GlIcon,
  GlIntersectionObserver,
  GlTooltipDirective,
} from '@gitlab/ui';
import { n__, __ } from '~/locale';
import Timeago from '~/vue_shared/components/time_ago_tooltip.vue';
import { ROUTES } from '../../constants';

export default {
  components: {
    GlCard,
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
    workItemIid: {
      type: String,
      required: false,
      default: null,
    },
    useRouter: {
      type: Boolean,
      required: true,
    },
    isDragging: {
      type: Boolean,
      required: false,
      default: false,
    },
    workItemWebUrl: {
      type: String,
      required: true,
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
          classes: 'gl-fill-icon-success',
          tooltip: __('Added in this version'),
        },
        modification: {
          name: 'file-modified-solid',
          classes: 'gl-fill-icon-info',
          tooltip: __('Modified in this version'),
        },
        deletion: {
          name: 'file-deletion-solid',
          classes: 'gl-fill-icon-danger',
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
    routerLinkProps() {
      return {
        name: this.$options.ROUTES.design,
        params: { iid: this.workItemIid, id: this.filename },
        query: this.$route.query,
      };
    },
    nonRouterHref() {
      return `${this.workItemWebUrl}/designs/${this.filename}`;
    },
    linkComponent() {
      return this.useRouter ? 'router-link' : 'a';
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
    onTileClick(event) {
      if (this.isDragging) {
        event.preventDefault();
      }
    },
  },
  ROUTES,
};
</script>

<template>
  <component
    :is="linkComponent"
    :to="routerLinkProps"
    :href="nonRouterHref"
    class="gl-block gl-text-default hover:gl-text-default focus:gl-focus"
  >
    <gl-card
      class="js-design-list-item design-list-item gl-mb-0 gl-border-section hover:gl-border-strong"
      header-class=" gl-p-0 gl-flex gl-grow gl-items-center gl-justify-center gl-overflow-hidden gl-relative gl-aspect-video"
      body-class="gl-py-3 gl-px-4 gl-flex gl-bg-section gl-rounded-b-base"
      @click="onTileClick"
    >
      <template #header>
        <div
          v-if="icon.name"
          data-testid="design-event"
          class="gl-absolute gl-right-3 gl-top-2 gl-mr-1 gl-mt-1"
        >
          <span :title="icon.tooltip" :aria-label="icon.tooltip">
            <gl-icon
              :name="icon.name"
              :size="16"
              :class="icon.classes"
              data-testid="design-status-icon"
              :data-qa-status="icon.name"
            />
          </span>
        </div>
        <gl-intersection-observer
          class="gl-flex gl-grow gl-items-center gl-justify-center"
          data-testid="design-image"
          :data-qa-filename="filename"
          @appear="onAppear"
        >
          <gl-loading-icon v-if="showLoadingSpinner" size="md" />
          <gl-icon v-else-if="showImageErrorIcon" name="media-broken" :size="32" variant="subtle" />
          <img
            v-show="showImage"
            :src="imageLink"
            :alt="filename"
            class="design-img gl-mx-auto gl-block gl-max-h-full gl-w-auto gl-max-w-full"
            :data-testid="`design-img-${id}`"
            @load="onImageLoad"
            @error="onImageError"
          />
        </gl-intersection-observer>
      </template>

      <template #default>
        <div class="gl-flex gl-flex-col gl-truncate" data-testid="design-file-name">
          <span
            v-gl-tooltip
            class="gl-truncate gl-text-sm"
            :data-testid="`design-img-filename-${id}`"
            :title="filename"
            >{{ filename }}</span
          >
          <span v-if="updatedAt" class="gl-truncate">
            {{ __('Updated') }} <timeago :time="updatedAt" tooltip-placement="bottom" />
          </span>
        </div>
        <div v-if="notesCount" class="gl-ml-auto gl-flex gl-items-center gl-text-subtle">
          <gl-icon name="comments" class="gl-ml-2" />
          <span :aria-label="notesLabel" class="gl-ml-2 gl-text-sm">
            {{ notesCount }}
          </span>
        </div>
      </template>
    </gl-card>
  </component>
</template>

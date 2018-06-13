<script>
import ImageViewer from '../../content_viewer/viewers/image_viewer.vue';
import TwoUpViewer from './image_diff/two_up_viewer.vue';
import SwipeViewer from './image_diff/swipe_viewer.vue';
import OnionSkinViewer from './image_diff/onion_skin_viewer.vue';
import { diffModes, imageViewMode } from '../constants';

export default {
  components: {
    ImageViewer,
    TwoUpViewer,
    SwipeViewer,
    OnionSkinViewer,
  },
  props: {
    diffMode: {
      type: String,
      required: true,
    },
    newPath: {
      type: String,
      required: true,
    },
    oldPath: {
      type: String,
      required: true,
    },
    projectPath: {
      type: String,
      required: false,
      default: '',
    },
  },
  data() {
    return {
      mode: imageViewMode.twoup,
    };
  },
  methods: {
    changeMode(newMode) {
      this.mode = newMode;
    },
  },
  diffModes,
  imageViewMode,
};
</script>

<template>
  <div class="diff-file-container">
    <div
      v-if="diffMode === $options.diffModes.replaced"
      class="diff-viewer">
      <div class="image js-replaced-image">
        <two-up-viewer
          v-if="mode === $options.imageViewMode.twoup"
          v-bind="$props"/>
        <swipe-viewer
          v-else-if="mode === $options.imageViewMode.swipe"
          v-bind="$props"/>
        <onion-skin-viewer
          v-else-if="mode === $options.imageViewMode.onion"
          v-bind="$props"/>
      </div>
      <div class="view-modes">
        <ul class="view-modes-menu">
          <li
            :class="{
              active: mode === $options.imageViewMode.twoup
            }"
            @click="changeMode($options.imageViewMode.twoup)">
            {{ s__('ImageDiffViewer|2-up') }}
          </li>
          <li
            :class="{
              active: mode === $options.imageViewMode.swipe
            }"
            @click="changeMode($options.imageViewMode.swipe)">
            {{ s__('ImageDiffViewer|Swipe') }}
          </li>
          <li
            :class="{
              active: mode === $options.imageViewMode.onion
            }"
            @click="changeMode($options.imageViewMode.onion)">
            {{ s__('ImageDiffViewer|Onion skin') }}
          </li>
        </ul>
      </div>
      <div class="note-container"></div>
    </div>
    <div
      v-else-if="diffMode === $options.diffModes.new"
      class="diff-viewer added">
      <image-viewer
        :path="newPath"
        :project-path="projectPath"
      />
    </div>
    <div
      v-else
      class="diff-viewer deleted">
      <image-viewer
        :path="oldPath"
        :project-path="projectPath"
      />
    </div>
  </div>
</template>

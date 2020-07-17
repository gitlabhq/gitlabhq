<script>
import $ from 'jquery';
import { GlButton } from '@gitlab/ui';
import { __ } from '~/locale';
import createFlash from '~/flash';
import StatusIcon from '../mr_widget_status_icon.vue';
import tooltip from '../../../vue_shared/directives/tooltip';
import eventHub from '../../event_hub';

export default {
  name: 'WorkInProgress',
  components: {
    StatusIcon,
    GlButton,
  },
  directives: {
    tooltip,
  },
  props: {
    mr: { type: Object, required: true },
    service: { type: Object, required: true },
  },
  data() {
    return {
      isMakingRequest: false,
    };
  },
  methods: {
    handleRemoveWIP() {
      this.isMakingRequest = true;
      this.service
        .removeWIP()
        .then(res => res.data)
        .then(data => {
          eventHub.$emit('UpdateWidgetData', data);
          createFlash(__('The merge request can now be merged.'), 'notice');
          $('.merge-request .detail-page-description .title').text(this.mr.title);
        })
        .catch(() => {
          this.isMakingRequest = false;
          createFlash(__('Something went wrong. Please try again.'));
        });
    },
  },
};
</script>

<template>
  <div class="mr-widget-body media">
    <status-icon :show-disabled-button="Boolean(mr.removeWIPPath)" status="warning" />
    <div class="media-body">
      <div class="gl-ml-3 float-left">
        <span class="gl-font-weight-bold">
          {{ __('This merge request is still a work in progress.') }}
        </span>
        <span class="gl-display-block text-muted">{{
          __("Draft merge requests can't be merged.")
        }}</span>
      </div>
      <gl-button
        v-if="mr.removeWIPPath"
        size="small"
        :disabled="isMakingRequest"
        :loading="isMakingRequest"
        class="js-remove-wip gl-ml-3"
        @click="handleRemoveWIP"
      >
        {{ s__('mrWidget|Mark as ready') }}
      </gl-button>
    </div>
  </div>
</template>

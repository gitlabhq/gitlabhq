<script>
import $ from 'jquery';
import { GlButton } from '@gitlab/ui';
import { __, s__ } from '~/locale';
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
  computed: {
    wipInfoTooltip() {
      return s__(
        'mrWidget|When this merge request is ready, remove the WIP: prefix from the title to allow it to be merged',
      );
    },
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
    <div class="media-body space-children">
      <span class="bold">
        {{ __('This is a Work in Progress') }}
        <i
          v-tooltip
          class="fa fa-question-circle"
          :title="wipInfoTooltip"
          :aria-label="wipInfoTooltip"
        >
        </i>
      </span>
      <gl-button
        v-if="mr.removeWIPPath"
        size="sm"
        variant="default"
        :disabled="isMakingRequest"
        :loading="isMakingRequest"
        class="js-remove-wip"
        @click="handleRemoveWIP"
      >
        {{ s__('mrWidget|Resolve WIP status') }}
      </gl-button>
    </div>
  </div>
</template>

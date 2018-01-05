<script>
  import { s__ } from '~/locale';
  import { spriteIcon } from '~/lib/utils/common_utils';
  import modal from './mr_widget_dast_modal.vue';

  const modalDefaultData = {
    modalId: 'modal-mrwidget-issue',
    modalDesc: '',
    modalTitle: '',
    modalInstances: [],
    modalTargetId: '#modal-mrwidget-issue',
  };

  export default {
    name: 'mrWidgetReportIssues',
    props: {
      issues: {
        type: Array,
        required: true,
      },
      // security || codequality || performance || docker || dast
      type: {
        type: String,
        required: true,
      },
      // failed || success
      status: {
        type: String,
        required: true,
      },
      hasPriority: {
        type: Boolean,
        required: false,
        default: false,
      },
    },
    data() {
      return modalDefaultData;
    },
    components: {
      modal,
    },
    computed: {
      icon() {
        return this.isStatusSuccess ? spriteIcon('plus') : this.cutIcon;
      },
      cutIcon() {
        return spriteIcon('cut');
      },
      fixedLabel() {
        return s__('ciReport|Fixed:');
      },
      isStatusFailed() {
        return this.status === 'failed';
      },
      isStatusSuccess() {
        return this.status === 'success';
      },
      isStatusNeutral() {
        return this.status === 'neutral';
      },
      isTypeQuality() {
        return this.type === 'codequality';
      },
      isTypePerformance() {
        return this.type === 'performance';
      },
      isTypeSecurity() {
        return this.type === 'security';
      },
      isTypeDocker() {
        return this.type === 'docker';
      },
      isTypeDast() {
        return this.type === 'dast';
      },
    },
    methods: {
      shouldRenderPriority(issue) {
        return this.hasPriority && issue.priority;
      },
      getmodalId(index) {
        return `modal-mrwidget-issue-${index}`;
      },
      modalIdTarget(index) {
        return `#${this.getmodalId(index)}`;
      },
      openDastModal(issue, index) {
        this.modalId = this.getmodalId(index);
        this.modalTitle = `${issue.priority}: ${issue.name}`;
        this.modalTargetId = `#${this.getmodalId(index)}`;
        this.modalInstances = issue.instances;
        this.modalDesc = issue.parsedDescription;
      },
      /**
       * Because of https://vuejs.org/v2/guide/list.html#Caveats
       * we need to clear the instances to make sure everything is properly reset.
       */
      clearModalData() {
        this.modalId = modalDefaultData.modalId;
        this.modalDesc = modalDefaultData.modalDesc;
        this.modalTitle = modalDefaultData.modalTitle;
        this.modalInstances = modalDefaultData.modalInstances;
        this.modalTargetId = modalDefaultData.modalTargetId;
      },
    },
  };
</script>
<template>
  <ul class="mr-widget-code-quality-list">
    <li
      :class="{
        failed: isStatusFailed,
        success: isStatusSuccess,
        neutral: isStatusNeutral
      }
      "v-for="(issue, index) in issues"
      :key="index"
      >

     <span
        class="mr-widget-code-quality-icon"
        v-html="icon"
        >
      </span>

      <template v-if="isStatusSuccess && isTypeQuality">{{ fixedLabel }}</template>
      <template v-if="shouldRenderPriority(issue)">{{issue.priority}}:</template>

      <template v-if="isTypeDocker">
        <a
          v-if="issue.nameLink"
          :href="issue.nameLink"
          target="_blank"
          rel="noopener noreferrer nofollow">
          {{issue.name}}
        </a>
        <template v-else>
          {{issue.name}}
        </template>
      </template>
      <template v-else-if="isTypeDast">
        <button
          type="button"
          @click="openDastModal(issue, index)"
          data-toggle="modal"
          class="btn-link btn-blank"
          :data-target="modalTargetId"
          >
          {{issue.name}}
        </button>
      </template>
      <template v-else>
        {{issue.name}}<template v-if="issue.score">: <strong>{{issue.score}}</strong></template>
      </template>

      <template v-if="isTypePerformance && issue.delta != null">
        ({{issue.delta >= 0 ? '+' : ''}}{{issue.delta}})
      </template>

      <template v-if="issue.path">
        in

        <a
          v-if="issue.urlPath"
          :href="issue.urlPath"
          target="_blank"
          rel="noopener noreferrer nofollow">
          {{issue.path}}<template v-if="issue.line">:{{issue.line}}</template>
        </a>
        <template v-else>
          {{issue.path}}<template v-if="issue.line">:{{issue.line}}</template>
        </template>
      </template>
    </li>

    <modal
      :target-id="modalId"
      :title="modalTitle"
      :hide-footer="true"
      :description="modalDesc"
      :instances="modalInstances"
      @clearData="clearModalData()"
      />
    </modal>
  </ul>
</template>

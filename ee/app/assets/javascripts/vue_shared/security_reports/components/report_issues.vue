<script>
  import { s__ } from '~/locale';
  import Icon from '~/vue_shared/components/icon.vue';
  import Modal from './dast_modal.vue';

  const modalDefaultData = {
    modalId: 'modal-mrwidget-issue',
    modalDesc: '',
    modalTitle: '',
    modalInstances: [],
    modalTargetId: '#modal-mrwidget-issue',
  };

  export default {
    name: 'ReportIssues',
    components: {
      Modal,
      Icon,
    },
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
    computed: {
      fixedLabel() {
        return s__('ciReport|Fixed:');
      },
      iconName() {
        if (this.isStatusFailed) {
          return 'status_failed_borderless';
        } else if (this.isStatusSuccess) {
          return 'status_success_borderless';
        }

        return 'status_created_borderless';
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
      formatScore(value) {
        if (Math.floor(value) !== value) {
          return parseFloat(value).toFixed(2);
        }
        return value;
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
  <ul class="report-block-list">
    <li
      :class="{
        failed: isStatusFailed,
        success: isStatusSuccess,
        neutral: isStatusNeutral
      }"
      class="report-block-list-item"
      v-for="(issue, index) in issues"
      :key="index"
    >
      <icon
        class="report-block-icon"
        :name="iconName"
        :size="32"
      />

      <template v-if="isStatusSuccess && isTypeQuality">{{ fixedLabel }}</template>
      <template v-if="shouldRenderPriority(issue)">{{ issue.priority }}:</template>

      <template v-if="isTypeDocker">
        <a
          v-if="issue.nameLink"
          :href="issue.nameLink"
          target="_blank"
          rel="noopener noreferrer nofollow"
          class="prepend-left-5"
        >
          {{ issue.name }}
        </a>
        <template v-else>
          {{ issue.name }}
        </template>
      </template>
      <template v-else-if="isTypeDast">
        <button
          type="button"
          @click="openDastModal(issue, index)"
          data-toggle="modal"
          class="btn-link btn-blank btn-open-modal"
          :data-target="modalTargetId"
        >
          {{ issue.name }}
        </button>
      </template>
      <template v-else>
        {{ issue.name }}<template v-if="issue.score">:
        <strong>{{ formatScore(issue.score) }}</strong></template>
      </template>

      <template v-if="isTypePerformance && issue.delta != null">
        ({{ issue.delta >= 0 ? '+' : '' }}{{ formatScore(issue.delta) }})
      </template>

      <template v-if="issue.path">
        in

        <a
          v-if="issue.urlPath"
          :href="issue.urlPath"
          target="_blank"
          rel="noopener noreferrer nofollow"
          class="prepend-left-5"
        >
          {{ issue.path }}<template v-if="issue.line">:{{ issue.line }}</template>
        </a>
        <template v-else>
          {{ issue.path }}<template v-if="issue.line">:{{ issue.line }}</template>
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
  </ul>
</template>

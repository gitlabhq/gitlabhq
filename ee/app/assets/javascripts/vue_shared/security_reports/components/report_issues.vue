<script>
import $ from 'jquery';
import Icon from '~/vue_shared/components/icon.vue';
import Modal from '~/vue_shared/components/gl_modal.vue';
import ExpandButton from '~/vue_shared/components/expand_button.vue';
import PerformanceIssue from 'ee/vue_merge_request_widget/components/performance_issue_body.vue';
import CodequalityIssue from 'ee/vue_merge_request_widget/components/codequality_issue_body.vue';
import SastIssue from './sast_issue_body.vue';
import SastContainerIssue from './sast_container_issue_body.vue';
import DastIssue from './dast_issue_body.vue';

import { SAST, DAST, SAST_CONTAINER } from '../store/constants';

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
    ExpandButton,
    SastIssue,
    SastContainerIssue,
    DastIssue,
    PerformanceIssue,
    CodequalityIssue,
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
  },
  data() {
    return modalDefaultData;
  },
  computed: {
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
    isTypeCodequality() {
      return this.type === 'codequality';
    },
    isTypePerformance() {
      return this.type === 'performance';
    },
    isTypeSast() {
      return this.type === SAST;
    },
    isTypeSastContainer() {
      return this.type === SAST_CONTAINER;
    },
    isTypeDast() {
      return this.type === DAST;
    },
  },
  mounted() {
    $(this.$refs.modal).on('hidden.bs.modal', () => {
      this.clearModalData();
    });
  },
  methods: {
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
  <div>
    <ul class="report-block-list">
      <li
        class="report-block-list-issue"
        v-for="(issue, index) in issues"
        :key="index"
      >
        <div
          class="report-block-list-icon append-right-5"
          :class="{
            failed: isStatusFailed,
            success: isStatusSuccess,
            neutral: isStatusNeutral,
          }"
        >
          <icon
            :name="iconName"
            :size="32"
          />
        </div>

        <sast-issue
          v-if="isTypeSast"
          :issue="issue"
        />

        <dast-issue
          v-else-if="isTypeDast"
          :issue="issue"
          :issue-index="index"
          :modal-target-id="modalTargetId"
          @openDastModal="openDastModal"
        />

        <sast-container-issue
          v-else-if="isTypeSastContainer"
          :issue="issue"
        />

        <codequality-issue
          v-else-if="isTypeCodequality"
          :is-status-success="isStatusSuccess"
          :issue="issue"
        />

        <performance-issue
          v-else-if="isTypePerformance"
          :issue="issue"
        />
      </li>
    </ul>

    <modal
      v-if="isTypeDast"
      :id="modalId"
      :header-title-text="modalTitle"
      ref="modal"
      class="modal-security-report-dast"
    >

      <slot>
        {{ modalDesc }}

        <h5 class="prepend-top-20">
          {{ s__('ciReport|Instances') }}
        </h5>

        <ul
          v-if="modalInstances"
          class="report-block-list"
        >
          <li
            v-for="(instance, i) in modalInstances"
            :key="i"
            class="report-block-list-issue"
          >
            <div class="report-block-list-icon append-right-5 failed">
              <icon
                name="status_failed_borderless"
                :size="32"
              />
            </div>
            <div class="report-block-list-issue-description prepend-top-5 append-bottom-5">
              <div class="report-block-list-issue-description-text append-right-5">
                {{ instance.method }}
              </div>
              <div class="report-block-list-issue-description-link">
                <a
                  :href="instance.uri"
                  target="_blank"
                  rel="noopener noreferrer nofollow"
                  class="break-link"
                >
                  {{ instance.uri }}
                </a>
              </div>
              <expand-button v-if="instance.evidence">
                <pre
                  slot="expanded"
                  class="block report-block-dast-code prepend-top-10 report-block-issue-code"
                >{{ instance.evidence }}</pre>
              </expand-button>
            </div>
          </li>
        </ul>
      </slot>
      <div slot="footer">
      </div>
    </modal>
  </div>
</template>

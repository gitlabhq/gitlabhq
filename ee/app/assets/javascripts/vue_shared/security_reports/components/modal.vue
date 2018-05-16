<script>
import { mapActions, mapState } from 'vuex';
import { s__ } from '~/locale';
import Modal from '~/vue_shared/components/gl_modal.vue';
import LoadingButton from '~/vue_shared/components/loading_button.vue';
import Icon from '~/vue_shared/components/icon.vue';
import ExpandButton from '~/vue_shared/components/expand_button.vue';

export default {
  components: {
    Modal,
    LoadingButton,
    ExpandButton,
    Icon,
  },
  computed: {
    ...mapState(['modal', 'vulnerabilityFeedbackHelpPath']),
    revertTitle() {
      return this.modal.vulnerability.isDismissed
        ? s__('ciReport|Revert dismissal')
        : s__('ciReport|Dismiss vulnerability');
    },
  },
  methods: {
    ...mapActions(['dismissIssue', 'revertDismissIssue', 'createNewIssue']),
    handleDismissClick() {
      if (this.modal.vulnerability.isDismissed) {
        this.revertDismissIssue();
      } else {
        this.dismissIssue();
      }
    },

    hasInstances(field, key) {
      return key === 'instances' && field.value && field.value.length > 0;
    },
  },
};
</script>
<template>
  <modal
    id="modal-mrwidget-security-issue"
    :header-title-text="modal.title"
    class="modal-security-report-dast"
  >
    <slot>
      <div
        v-for="(field, key, index) in modal.data"
        v-if="field.value || hasInstances(field, key)"
        class="row prepend-top-10 append-bottom-10"
        :key="index"
      >
        <label class="col-sm-2 text-right">
          {{ field.text }}:
        </label>
        <div class="col-sm-10 text-secondary">
          <div
            v-if="hasInstances(field, key)"
            class="well"
          >
            <ul class="report-block-list">
              <li
                v-for="(instance, i) in field.value"
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
          </div>
          <template v-else>
            <a
              :class="`js-link-${key}`"
              v-if="field.isLink"
              target="_blank"
              :href="field.url"
            >
              {{ field.value }}
            </a>
            <span v-else>
              {{ field.value }}
            </span>
          </template>
        </div>
      </div>

      <div class="row prepend-top-20 append-bottom-10">
        <div class="col-sm-10 col-sm-offset-2 text-secondary">
          <a
            class="js-link-vulnerabilityFeedbackHelpPath"
            :href="vulnerabilityFeedbackHelpPath"
          >
            Learn more about interacting with security reports (Alpha).
          </a>
        </div>
      </div>

      <div
        v-if="modal.error"
        class="alert alert-danger"
      >
        {{ modal.error }}
      </div>
    </slot>
    <div slot="footer">
      <button
        type="button"
        class="btn btn-default"
        data-dismiss="modal"
      >
        {{ __('Cancel' ) }}
      </button>

      <loading-button
        container-class="js-dismiss-btn btn btn-close"
        :loading="modal.isDismissingIssue"
        :disabled="modal.isDismissingIssue"
        @click="handleDismissClick"
        :label="revertTitle"
      />

      <a
        v-if="modal.vulnerability.hasIssue"
        :href="modal.vulnerability.issueFeedback && modal.vulnerability.issueFeedback.issue_url"
        rel="noopener noreferrer nofollow"
        class="btn btn-success btn-inverted"
      >
        {{ __('View issue' ) }}
      </a>
      <loading-button
        v-else
        container-class="btn btn-success btn-inverted"
        :loading="modal.isCreatingNewIssue"
        :disabled="modal.isCreatingNewIssue"
        @click="createNewIssue"
        :label="__('Create issue')"
      />
    </div>
  </modal>
</template>

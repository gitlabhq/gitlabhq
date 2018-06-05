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
    hasDismissedBy() {
      return this.modal.vulnerability.dismissalFeedback &&
        this.modal.vulnerability.dismissalFeedback.pipeline &&
        this.modal.vulnerability.dismissalFeedback.author;
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
    isLastValue(index, values) {
      return index < values.length - 1;
    },
    hasValue(field) {
      return field.value && field.value.length > 0;
    },
    hasInstances(field, key) {
      return key === 'instances' && this.hasValue(field);
    },
    hasIdentifiers(field, key) {
      return key === 'identifiers' && this.hasValue(field);
    },
    hasLinks(field, key) {
      return key === 'links' && this.hasValue(field);
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
        v-if="field.value"
        class="row prepend-top-10 append-bottom-10"
        :key="index"
      >
        <label class="col-sm-2 text-right font-weight-bold">
          {{ field.text }}:
        </label>
        <div class="col-sm-10 text-secondary">
          <div
            v-if="hasInstances(field, key)"
            class="info-well"
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
                  <div class="report-block-list-issue-description-text">
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
          <template v-else-if="hasIdentifiers(field, key)">
            <span
              v-for="(identifier, i) in field.value"
              :key="i"
            >
              <a
                :class="`js-link-${key}`"
                v-if="identifier.url"
                target="_blank"
                :href="identifier.url"
                rel="noopener noreferrer"
              >
                {{ identifier.name }}
              </a>
              <span v-else>
                {{ identifier.name }}
              </span>
              <span v-if="isLastValue(i, field.value)">,&nbsp;</span>
            </span>
          </template>
          <template v-else-if="hasLinks(field, key)">
            <span
              v-for="(link, i) in field.value"
              :key="i"
            >
              <a
                :class="`js-link-${key}`"
                target="_blank"
                :href="link.url"
                rel="noopener noreferrer"
              >
                {{ link.value || link.url }}
              </a>
              <span v-if="isLastValue(i, field.value)">,&nbsp;</span>
            </span>
          </template>
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
        <div class="col-sm-10 offset-sm-2 text-secondary">
          <template v-if="hasDismissedBy">
            {{ s__('ciReport|Dismissed by') }}
            <a
              :href="modal.vulnerability.dismissalFeedback.author.web_url"
              class="pipeline-id"
            >
              @{{ modal.vulnerability.dismissalFeedback.author.username }}
            </a>
            {{ s__('ciReport|on pipeline') }}
            <a
              :href="modal.vulnerability.dismissalFeedback.pipeline.path"
              class="pipeline-id"
            >#{{ modal.vulnerability.dismissalFeedback.pipeline.id }}</a>.
          </template>
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

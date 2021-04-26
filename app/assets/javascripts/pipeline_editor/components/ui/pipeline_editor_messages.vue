<script>
import { GlAlert } from '@gitlab/ui';
import { getParameterValues, removeParams } from '~/lib/utils/url_utility';
import { __, s__ } from '~/locale';
import {
  COMMIT_FAILURE,
  COMMIT_SUCCESS,
  DEFAULT_FAILURE,
  DEFAULT_SUCCESS,
  LOAD_FAILURE_UNKNOWN,
} from '../../constants';
import CodeSnippetAlert from '../code_snippet_alert/code_snippet_alert.vue';
import {
  CODE_SNIPPET_SOURCE_URL_PARAM,
  CODE_SNIPPET_SOURCES,
} from '../code_snippet_alert/constants';

export default {
  components: {
    GlAlert,
    CodeSnippetAlert,
  },
  errorTexts: {
    [COMMIT_FAILURE]: s__('Pipelines|The GitLab CI configuration could not be updated.'),
    [DEFAULT_FAILURE]: __('Something went wrong on our end.'),
    [LOAD_FAILURE_UNKNOWN]: s__('Pipelines|The CI configuration was not loaded, please try again.'),
  },
  successTexts: {
    [COMMIT_SUCCESS]: __('Your changes have been successfully committed.'),
    [DEFAULT_SUCCESS]: __('Your action succeeded.'),
  },
  props: {
    failureType: {
      type: String,
      required: false,
      default: null,
    },
    failureReasons: {
      type: Array,
      required: false,
      default: () => [],
    },
    showFailure: {
      type: Boolean,
      required: false,
      default: false,
    },
    showSuccess: {
      type: Boolean,
      required: false,
      default: false,
    },
    successType: {
      type: String,
      required: false,
      default: null,
    },
  },
  data() {
    return {
      codeSnippetCopiedFrom: '',
    };
  },
  computed: {
    failure() {
      switch (this.failureType) {
        case LOAD_FAILURE_UNKNOWN:
          return {
            text: this.$options.errorTexts[LOAD_FAILURE_UNKNOWN],
            variant: 'danger',
          };
        case COMMIT_FAILURE:
          return {
            text: this.$options.errorTexts[COMMIT_FAILURE],
            variant: 'danger',
          };
        default:
          return {
            text: this.$options.errorTexts[DEFAULT_FAILURE],
            variant: 'danger',
          };
      }
    },
    success() {
      switch (this.successType) {
        case COMMIT_SUCCESS:
          return {
            text: this.$options.successTexts[COMMIT_SUCCESS],
            variant: 'info',
          };
        default:
          return {
            text: this.$options.successTexts[DEFAULT_SUCCESS],
            variant: 'info',
          };
      }
    },
  },
  created() {
    this.parseCodeSnippetSourceParam();
  },
  methods: {
    dismissCodeSnippetAlert() {
      this.codeSnippetCopiedFrom = '';
    },
    dismissFailure() {
      this.$emit('hide-failure');
    },
    dismissSuccess() {
      this.$emit('hide-success');
    },
    parseCodeSnippetSourceParam() {
      const [codeSnippetCopiedFrom] = getParameterValues(CODE_SNIPPET_SOURCE_URL_PARAM);
      if (codeSnippetCopiedFrom && CODE_SNIPPET_SOURCES.includes(codeSnippetCopiedFrom)) {
        this.codeSnippetCopiedFrom = codeSnippetCopiedFrom;
        window.history.replaceState(
          {},
          document.title,
          removeParams([CODE_SNIPPET_SOURCE_URL_PARAM]),
        );
      }
    },
  },
};
</script>

<template>
  <div>
    <code-snippet-alert
      v-if="codeSnippetCopiedFrom"
      :source="codeSnippetCopiedFrom"
      class="gl-mb-5"
      @dismiss="dismissCodeSnippetAlert"
    />
    <gl-alert
      v-if="showSuccess"
      :variant="success.variant"
      class="gl-mb-5"
      @dismiss="dismissSuccess"
    >
      {{ success.text }}
    </gl-alert>
    <gl-alert
      v-if="showFailure"
      :variant="failure.variant"
      class="gl-mb-5"
      @dismiss="dismissFailure"
    >
      {{ failure.text }}
      <ul v-if="failureReasons.length" class="gl-mb-0">
        <li v-for="reason in failureReasons" :key="reason">{{ reason }}</li>
      </ul>
    </gl-alert>
  </div>
</template>

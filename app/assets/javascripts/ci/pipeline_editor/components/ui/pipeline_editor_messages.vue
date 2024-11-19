<script>
import { GlAlert } from '@gitlab/ui';
import { getParameterValues, removeParams } from '~/lib/utils/url_utility';
import { __, s__ } from '~/locale';
import {
  COMMIT_FAILURE,
  DEFAULT_FAILURE,
  LOAD_FAILURE_UNKNOWN,
  PIPELINE_FAILURE,
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

  errors: {
    [COMMIT_FAILURE]: s__('Pipelines|The GitLab CI configuration could not be updated.'),
    [DEFAULT_FAILURE]: __('Something went wrong on our end.'),
    [LOAD_FAILURE_UNKNOWN]: s__('Pipelines|The CI configuration was not loaded, please try again.'),
    [PIPELINE_FAILURE]: s__('Pipelines|There was a problem with loading the pipeline data.'),
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
  },
  data() {
    return {
      codeSnippetCopiedFrom: '',
    };
  },
  computed: {
    failure() {
      const { errors } = this.$options;

      return {
        text: errors[this.failureType] ?? errors[DEFAULT_FAILURE],
        variant: 'danger',
      };
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

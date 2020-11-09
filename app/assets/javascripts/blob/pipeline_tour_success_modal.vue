<script>
import { GlModal, GlSprintf, GlLink, GlButton } from '@gitlab/ui';
import Cookies from 'js-cookie';
import { s__ } from '~/locale';
import Tracking from '~/tracking';

const trackingMixin = Tracking.mixin();

export default {
  beginnerLink:
    'https://about.gitlab.com/blog/2018/01/22/a-beginners-guide-to-continuous-integration/',
  goToTrackValuePipelines: 10,
  goToTrackValueMergeRequest: 20,
  trackEvent: 'click_button',
  components: {
    GlModal,
    GlSprintf,
    GlButton,
    GlLink,
  },
  mixins: [trackingMixin],
  props: {
    goToPipelinesPath: {
      type: String,
      required: true,
    },
    projectMergeRequestsPath: {
      type: String,
      required: false,
      default: '',
    },
    commitCookie: {
      type: String,
      required: true,
    },
    humanAccess: {
      type: String,
      required: true,
    },
    exampleLink: {
      type: String,
      required: true,
    },
    codeQualityLink: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      trackLabel: 'congratulate_first_pipeline',
    };
  },
  computed: {
    tracking() {
      return {
        label: this.trackLabel,
        property: this.humanAccess,
      };
    },
    goToMergeRequestPath() {
      return this.commitCookiePath || this.projectMergeRequestsPath;
    },
    commitCookiePath() {
      const cookieVal = Cookies.get(this.commitCookie);

      if (cookieVal !== 'true') return cookieVal;
      return '';
    },
  },
  i18n: {
    modalTitle: s__("That's it, well done!"),
    pipelinesButton: s__('MR widget|See your pipeline in action'),
    mergeRequestButton: s__('MR widget|Back to the Merge request'),
    bodyMessage: s__(
      `MR widget|The pipeline will test your code on every commit. A %{codeQualityLinkStart}code quality report%{codeQualityLinkEnd} will appear in your merge requests to warn you about potential code degradations.`,
    ),
    helpMessage: s__(
      `MR widget|Take a look at our %{beginnerLinkStart}Beginner's Guide to Continuous Integration%{beginnerLinkEnd} and our %{exampleLinkStart}examples of GitLab CI/CD%{exampleLinkEnd} to learn more.`,
    ),
  },
  mounted() {
    this.track();
    this.disableModalFromRenderingAgain();
  },
  methods: {
    disableModalFromRenderingAgain() {
      Cookies.remove(this.commitCookie);
    },
  },
};
</script>
<template>
  <gl-modal visible size="sm" modal-id="success-pipeline-modal-id-not-used">
    <template #modal-title>
      {{ $options.i18n.modalTitle }}
      <gl-emoji class="gl-vertical-align-baseline font-size-inherit gl-mr-1" data-name="tada" />
    </template>
    <p>
      <gl-sprintf :message="$options.i18n.bodyMessage">
        <template #codeQualityLink="{content}">
          <gl-link :href="codeQualityLink" target="_blank" class="font-size-inherit">{{
            content
          }}</gl-link>
        </template>
      </gl-sprintf>
    </p>
    <gl-sprintf :message="$options.i18n.helpMessage">
      <template #beginnerLink="{content}">
        <gl-link :href="$options.beginnerLink" target="_blank">
          {{ content }}
        </gl-link>
      </template>
      <template #exampleLink="{content}">
        <gl-link :href="exampleLink" target="_blank">
          {{ content }}
        </gl-link>
      </template>
    </gl-sprintf>
    <template #modal-footer>
      <gl-button
        v-if="projectMergeRequestsPath"
        ref="goToMergeRequest"
        :href="goToMergeRequestPath"
        :data-track-property="humanAccess"
        :data-track-value="$options.goToTrackValueMergeRequest"
        :data-track-event="$options.trackEvent"
        :data-track-label="trackLabel"
      >
        {{ $options.i18n.mergeRequestButton }}
      </gl-button>
      <gl-button
        ref="goToPipelines"
        :href="goToPipelinesPath"
        variant="success"
        :data-track-property="humanAccess"
        :data-track-value="$options.goToTrackValuePipelines"
        :data-track-event="$options.trackEvent"
        :data-track-label="trackLabel"
      >
        {{ $options.i18n.pipelinesButton }}
      </gl-button>
    </template>
  </gl-modal>
</template>

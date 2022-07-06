<script>
import { GlButton, GlSprintf, GlSafeHtmlDirective } from '@gitlab/ui';
import gitlabLogo from '@gitlab/svgs/dist/illustrations/gitlab_logo.svg';
import { s__, __ } from '~/locale';
import UserCalloutDismisser from '~/vue_shared/components/user_callout_dismisser.vue';
import SatisfactionRate from '~/surveys/components/satisfaction_rate.vue';
import Tracking from '~/tracking';

const steps = [
  {
    label: 'overall',
    question: s__('MrSurvey|Overall, how satisfied are you with merge requests?'),
  },
  {
    label: 'performance',
    question: s__(
      'MrSurvey|How satisfied are you with %{strongStart}speed/performance%{strongEnd} of merge requests?',
    ),
  },
];

export default {
  name: 'MergeRequestExperienceSurveyApp',
  components: {
    UserCalloutDismisser,
    GlSprintf,
    GlButton,
    SatisfactionRate,
  },
  directives: {
    safeHtml: GlSafeHtmlDirective,
  },
  mixins: [Tracking.mixin()],
  i18n: {
    survey: s__('MrSurvey|Merge request experience survey'),
    close: __('Close'),
    legal: s__(
      'MrSurvey|By continuing, you acknowledge that responses will be used to improve GitLab and in accordance with the %{linkStart}GitLab Privacy Policy%{linkEnd}.',
    ),
    thanks: s__('MrSurvey|Thank you for your feedback!'),
  },
  gitlabLogo,
  data() {
    return {
      visible: false,
      stepIndex: 0,
    };
  },
  computed: {
    step() {
      return steps[this.stepIndex];
    },
  },
  mounted() {
    document.addEventListener('keyup', this.handleKeyup);
  },
  destroyed() {
    document.removeEventListener('keyup', this.handleKeyup);
  },
  methods: {
    onQueryLoaded({ shouldShowCallout }) {
      this.visible = shouldShowCallout;
      if (!this.visible) this.$emit('close');
    },
    onRate(event) {
      this.$emit('rate');
      this.track('survey:mr_experience', {
        label: this.step.label,
        value: event,
      });
      this.stepIndex += 1;
      if (!this.step) {
        setTimeout(() => {
          this.$emit('close');
        }, 5000);
      }
    },
    handleKeyup(e) {
      if (e.key !== 'Escape') return;
      this.$emit('close');
      this.$refs.dismisser?.dismiss();
    },
  },
};
</script>

<template>
  <user-callout-dismisser
    ref="dismisser"
    feature-name="mr_experience_survey"
    @queryResult.once="onQueryLoaded"
  >
    <template #default="{ dismiss }">
      <aside
        class="gl-fixed gl-bottom-0 gl-right-0 gl-z-index-9999 gl-p-5"
        :aria-label="$options.i18n.survey"
      >
        <transition name="survey-slide-up">
          <div
            v-if="visible"
            class="mr-experience-survey-body gl-relative gl-display-flex gl-flex-direction-column gl-bg-white gl-p-5 gl-border gl-rounded-base"
          >
            <gl-button
              :aria-label="$options.i18n.close"
              variant="default"
              category="tertiary"
              class="gl-top-4 gl-right-3 gl-absolute"
              icon="close"
              @click="
                dismiss();
                $emit('close');
              "
            />
            <div
              v-if="stepIndex === 0"
              class="mr-experience-survey-legal gl-border-t gl-mt-5 gl-pt-3 gl-text-gray-500 gl-font-sm"
              role="note"
            >
              <p class="gl-m-0">
                <gl-sprintf :message="$options.i18n.legal">
                  <template #link="{ content }">
                    <a
                      class="gl-text-decoration-underline gl-text-gray-500"
                      href="https://about.gitlab.com/privacy/"
                      target="_blank"
                      rel="noreferrer nofollow"
                      v-text="content"
                    ></a>
                  </template>
                </gl-sprintf>
              </p>
            </div>
            <div class="gl-relative">
              <div class="gl-absolute">
                <div
                  v-safe-html="$options.gitlabLogo"
                  aria-hidden="true"
                  class="mr-experience-survey-logo"
                ></div>
              </div>
            </div>
            <section v-if="step">
              <p id="mr_survey_question" ref="question" class="gl-m-0 gl-px-7">
                <gl-sprintf :message="step.question">
                  <template #strong="{ content }">
                    <strong>{{ content }}</strong>
                  </template>
                </gl-sprintf>
              </p>
              <satisfaction-rate
                aria-labelledby="mr_survey_question"
                class="gl-mt-5"
                @rate="
                  dismiss();
                  onRate($event);
                "
              />
            </section>
            <section v-else class="gl-px-7">
              {{ $options.i18n.thanks }}
            </section>
          </div>
        </transition>
      </aside>
    </template>
  </user-callout-dismisser>
</template>

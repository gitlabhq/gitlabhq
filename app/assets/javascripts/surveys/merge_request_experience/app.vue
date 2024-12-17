<script>
import { GlButton, GlSprintf, GlTooltipDirective } from '@gitlab/ui';
import gitlabLogo from '@gitlab/svgs/dist/illustrations/gitlab_logo.svg?raw';
import SafeHtml from '~/vue_shared/directives/safe_html';
import { s__, __ } from '~/locale';
import UserCalloutDismisser from '~/vue_shared/components/user_callout_dismisser.vue';
import SatisfactionRate from '~/surveys/components/satisfaction_rate.vue';
import Tracking from '~/tracking';
import { PROMO_URL } from '~/constants';

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

const MR_RENDER_LS_KEY = 'mr_survey_rendered';

export default {
  name: 'MergeRequestExperienceSurveyApp',
  components: {
    UserCalloutDismisser,
    GlSprintf,
    GlButton,
    SatisfactionRate,
  },
  directives: {
    SafeHtml,
    tooltip: GlTooltipDirective,
  },
  mixins: [Tracking.mixin()],
  props: {
    accountAge: {
      type: Number,
      required: true,
    },
  },
  i18n: {
    survey: s__('MrSurvey|Merge request experience survey'),
    close: __('Close'),
    legal: s__(
      'MrSurvey|By continuing, you acknowledge that responses will be used to improve GitLab and in accordance with the %{linkStart}GitLab Privacy Policy%{linkEnd}.',
    ),
    thanks: s__('MrSurvey|Thank you for your feedback!'),
  },
  gitlabLogo,
  privacyLink: `${PROMO_URL}/privacy/`,
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
      else if (!localStorage?.getItem(MR_RENDER_LS_KEY)) {
        this.track('survey:mr_experience', {
          label: 'render',
          extra: {
            accountAge: this.accountAge,
          },
        });
        localStorage?.setItem(MR_RENDER_LS_KEY, '1');
      }
    },
    onRate(event) {
      this.$refs.dismisser?.dismiss();
      this.$emit('rate');
      localStorage?.removeItem(MR_RENDER_LS_KEY);
      this.track('survey:mr_experience', {
        label: this.step.label,
        value: event,
        extra: {
          accountAge: this.accountAge,
        },
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
      this.dismiss();
    },
    dismiss() {
      this.$refs.dismisser?.dismiss();
      this.$emit('close');
      this.track('survey:mr_experience', {
        label: 'dismiss',
        extra: {
          accountAge: this.accountAge,
        },
      });
      localStorage?.removeItem(MR_RENDER_LS_KEY);
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
    <aside
      class="mr-experience-survey-wrapper gl-fixed gl-bottom-0 gl-right-0 gl-p-5"
      :aria-label="$options.i18n.survey"
    >
      <transition name="survey-slide-up">
        <div
          v-if="visible"
          class="mr-experience-survey-body gl-border gl-relative gl-flex gl-flex-col gl-rounded-base gl-bg-white gl-p-5"
        >
          <gl-button
            v-tooltip="$options.i18n.close"
            :aria-label="$options.i18n.close"
            variant="default"
            category="tertiary"
            class="gl-absolute gl-right-3 gl-top-4"
            icon="close"
            @click="dismiss"
          />
          <div
            v-if="stepIndex === 0"
            class="mr-experience-survey-legal gl-border-t gl-mt-5 gl-pt-3 gl-text-sm gl-text-subtle"
            role="note"
          >
            <p class="gl-m-0">
              <gl-sprintf :message="$options.i18n.legal">
                <template #link="{ content }">
                  <a
                    class="gl-text-subtle gl-underline"
                    :href="$options.privacyLink"
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
              @rate="onRate"
            />
          </section>
          <section v-else class="gl-px-7">
            {{ $options.i18n.thanks }}
          </section>
        </div>
      </transition>
    </aside>
  </user-callout-dismisser>
</template>

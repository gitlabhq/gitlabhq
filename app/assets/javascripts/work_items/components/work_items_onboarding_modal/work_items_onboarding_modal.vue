<script>
import { GlModal, GlButton, GlSprintf } from '@gitlab/ui';
import { __ } from '~/locale';
import Introduction from './animations/introduction.vue';
import Filters from './animations/filters.vue';
import Tabs from './animations/tabs.vue';
import SaveView from './animations/save_view.vue';

const ONBOARDING_STEPS = [
  {
    component: Introduction,
    body: __(
      'Epics, issues, and tasks are now %{boldStart}work items%{boldEnd}. We’ve improved how your team finds and organizes work with customizable views.',
    ),
    title: __('Introducing the work items list'),
  },
  {
    component: Filters,
    body: __(
      'Save views with your preferred filters and display options to plan and track work easier. Add views shared by your team or create your own.',
    ),
    title: __('Hone in on what’s important'),
  },
  // {
  //   component: Tabs,
  //   body: __(
  //     'The views that appear in your tabs at the top are specific to you. Add, reorder, and remove views to create the best setup for your needs.',
  //   ),
  //   title: __('Tailor your views list'),
  // },
  {
    component: SaveView,
    body: __(
      'In a group, epics and issues are all together under %{boldStart}Work items%{boldEnd}. To view them separately, filter the list by type and save the view.',
    ),
    title: __('All work items in one place'),
  },
];

export default {
  name: 'WorkItemsOnboardingModal',
  components: {
    GlModal,
    GlButton,
    GlSprintf,
    Introduction,
    Filters,
    Tabs,
    SaveView,
  },
  emits: ['close'],
  data() {
    return {
      currentStep: 0,
      modalVisible: true,
    };
  },
  computed: {
    steps() {
      return this.$options.ONBOARDING_STEPS;
    },
    step() {
      return this.steps[this.currentStep];
    },
    isFirstStep() {
      return this.currentStep === 0;
    },
    isLastStep() {
      return this.currentStep === this.steps.length - 1;
    },
    nextButtonText() {
      return this.isLastStep ? __('Get Started') : __('Next');
    },
  },
  methods: {
    handleNext() {
      if (this.isLastStep) {
        this.$emit('close');
        return;
      }

      setTimeout(() => {
        this.currentStep += 1;
      }, 150);
    },
    handleBack() {
      if (this.isFirstStep) return;

      setTimeout(() => {
        this.currentStep -= 1;
      }, 150);
    },
  },
  ONBOARDING_STEPS,
};
</script>

<template>
  <gl-modal
    v-model="modalVisible"
    data-testid="work-items-onboarding-modal"
    modal-id="work-items-onboarding-modal"
    size="sm"
    :aria-label="__(`Work Items Onboarding Modal`)"
    @hide="$emit('close')"
  >
    <div class="text-center">
      <transition name="fade" mode="out-in">
        <div :key="currentStep" class="gl-mb-5">
          <h2 class="gl-heading-2">{{ step.title }}</h2>
          <p>
            <gl-sprintf :message="step.body">
              <template #bold="{ content }">
                <strong>{{ content }}</strong>
              </template>
            </gl-sprintf>
          </p>
          <component :is="step.component" />
        </div>
      </transition>
    </div>

    <template #modal-footer>
      <div class="gl-m-0 gl-flex gl-w-full gl-items-center">
        <div class="gl-flex-1">
          <gl-button v-if="!isFirstStep" @click="handleBack">
            {{ __('Back') }}
          </gl-button>
        </div>

        <div class="step-indicators gl-flex gl-gap-2">
          <span
            v-for="(_, index) in steps"
            :key="index"
            class="gl-h-3 gl-w-3 gl-rounded-full"
            :class="index === currentStep ? 'gl-bg-neutral-950' : 'gl-bg-neutral-200'"
            data-testid="step-indicator"
          ></span>
        </div>

        <div class="gl-flex gl-flex-1 gl-justify-end">
          <gl-button variant="confirm" data-testid="next-button" @click="handleNext">
            {{ nextButtonText }}
          </gl-button>
        </div>
      </div>
    </template>
  </gl-modal>
</template>

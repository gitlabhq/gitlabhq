<script>
import { GlModal, GlButton } from '@gitlab/ui';
import ExplainerAi from './explainer_ai.vue';
import ExplainerFeedback from './explainer_feedback.vue';
import ExplainerPanels from './explainer_panels.vue';
import ExplainerSearch from './explainer_search.vue';
import ExplainerSidebar from './explainer_sidebar.vue';
import ExplainerUi from './explainer_ui.vue';

export default {
  name: 'DapWelcomeModalApp',
  components: {
    GlModal,
    GlButton,
    ExplainerAi,
    ExplainerFeedback,
    ExplainerPanels,
    ExplainerSearch,
    ExplainerSidebar,
    ExplainerUi,
  },
  data() {
    return {
      currentStep: 1,
    };
  },
  computed: {
    footerClasses() {
      if (this.currentStep === 1) {
        return 'gl-w-full gl-flex gl-gap-3 gl-items-center gl-flex-row-reverse gl-justify-center gl-m-0';
      }
      if (this.currentStep < 6) {
        return 'gl-w-full gl-flex gl-gap-3 gl-items-center gl-flex-row-reverse gl-justify-between gl-m-0';
      }
      return 'gl-w-full gl-flex gl-flex-wrap gl-gap-3 gl-items-center gl-flex-col md:gl-flex-row-reverse gl-justify-center md:gl-justify-between gl-m-0';
    },
  },
  mounted() {
    this.$refs.modal.show();
  },
  methods: {
    close() {
      this.$emit('close');
      this.$refs.modal.hide();
    },
    onBack() {
      this.currentStep -= 1;
    },
    onNext() {
      this.currentStep += 1;
    },
    onBulletClick(i) {
      this.currentStep = i;
    },
  },
};
</script>

<template>
  <gl-modal
    ref="modal"
    modal-id="dap_welcome_modal"
    :no-focus-on-show="false"
    size="sm"
    class="dap-welcome-modal"
    @close="close"
    @hide="close"
  >
    <h2 class="gl-heading-2">{{ __('Welcome to the redesigned GitLab UI') }}</h2>

    <div class="slides" :style="`--_currentStep: ${currentStep - 1}`">
      <explainer-ui :class="{ active: currentStep === 1 }" />
      <explainer-search :class="{ active: currentStep === 2 }" />
      <explainer-sidebar :class="{ active: currentStep === 3 }" />
      <explainer-panels :class="{ active: currentStep === 4 }" />
      <explainer-ai :class="{ active: currentStep === 5 }" />
      <explainer-feedback :class="{ active: currentStep === 6 }" />
    </div>

    <div class="particles">
      <div
        v-for="i in 20"
        :key="i"
        :style="`--size: ${Math.random()}; --blur: ${Math.random()}; --delay: ${Math.random()}; --duration: ${Math.random()};`"
        class="particle"
      ></div>
    </div>

    <template #modal-footer>
      <div :class="footerClasses">
        <gl-button v-if="currentStep === 1" variant="confirm" class="!gl-m-0" @click="onNext">
          {{ __('Get Started') }}
        </gl-button>
        <template v-else-if="currentStep < 6">
          <gl-button variant="confirm" class="!gl-m-0" @click="onNext">
            {{ __('Go Next') }}
          </gl-button>

          <div class="bullets">
            <button
              v-for="i in 5"
              :key="i"
              :class="['item', { active: currentStep === i + 1 }]"
              :aria-label="`Open slide ${i + 1}`"
              @click="onBulletClick(i + 1)"
            ></button>
          </div>
        </template>
        <template v-else-if="currentStep === 6">
          <gl-button variant="confirm" autofocus class="!gl-m-0" @click="close">
            {{ __('Go to GitLab') }}
          </gl-button>
          <gl-button
            href="https://gitlab.com/gitlab-org/gitlab/-/issues/577554"
            class="!gl-m-0"
            @click="close"
          >
            {{ __('Open feedback issue') }}
          </gl-button>
        </template>

        <gl-button v-if="currentStep > 1" variant="default" class="!gl-m-0" @click="onBack">
          {{ __('Go Back') }}
        </gl-button>
      </div>
    </template>
  </gl-modal>
</template>

<script>
import { GlButton, GlModal, GlModalDirective, GlLink, GlSprintf } from '@gitlab/ui';
import ModalCopyButton from '~/vue_shared/components/modal_copy_button.vue';
import { s__ } from '~/locale';

export default {
  components: {
    GlButton,
    GlLink,
    GlModal,
    GlSprintf,
    ModalCopyButton,
  },
  directives: {
    'gl-modal': GlModalDirective,
  },
  instructionText: {
    step1: s__(
      'EnableReviewApp|%{stepStart}Step 1%{stepEnd}. Ensure you have Kubernetes set up and have a base domain for your %{linkStart}cluster%{linkEnd}.',
    ),
    step2: s__('EnableReviewApp|%{stepStart}Step 2%{stepEnd}. Copy the following snippet:'),
    step3: s__(
      `EnableReviewApp|%{stepStart}Step 3%{stepEnd}. Add it to the project %{linkStart}gitlab-ci.yml%{linkEnd} file.`,
    ),
  },
  modalInfo: {
    closeText: s__('EnableReviewApp|Close'),
    copyToClipboardText: s__('EnableReviewApp|Copy snippet text'),
    copyString: `deploy_review
  stage: deploy
  script:
    - echo "Deploy a review app"
  environment:
    name: review/$CI_COMMIT_REF_NAME
    url: https://$CI_ENVIRONMENT_SLUG.example.com
  only: branches
  except: master`,
    id: 'enable-review-app-info',
    title: s__('ReviewApp|Enable Review App'),
  },
};
</script>
<template>
  <div>
    <gl-button
      v-gl-modal="$options.modalInfo.id"
      variant="info"
      category="secondary"
      type="button"
      class="js-enable-review-app-button"
    >
      {{ s__('Environments|Enable review app') }}
    </gl-button>
    <gl-modal
      :modal-id="$options.modalInfo.id"
      :title="$options.modalInfo.title"
      size="lg"
      class="text-2 ws-normal"
      ok-only
      ok-variant="light"
      :ok-title="$options.modalInfo.closeText"
    >
      <p>
        <gl-sprintf :message="$options.instructionText.step1">
          <template #step="{ content }">
            <strong>{{ content }}</strong>
          </template>
          <template #link="{ content }">
            <gl-link
              href="https://docs.gitlab.com/ee/user/project/clusters/add_remove_clusters.html"
              target="_blank"
              >{{ content }}</gl-link
            >
          </template>
        </gl-sprintf>
      </p>
      <div>
        <p>
          <gl-sprintf :message="$options.instructionText.step2">
            <template #step="{ content }">
              <strong>{{ content }}</strong>
            </template>
          </gl-sprintf>
        </p>
        <div class="flex align-items-start">
          <pre class="w-100"> {{ $options.modalInfo.copyString }} </pre>
          <modal-copy-button
            :title="$options.modalInfo.copyToClipboardText"
            :text="$options.modalInfo.copyString"
            :modal-id="$options.modalInfo.id"
            css-classes="border-0"
          />
        </div>
      </div>
      <p>
        <gl-sprintf :message="$options.instructionText.step3">
          <template #step="{ content }">
            <strong>{{ content }}</strong>
          </template>
          <template #link="{ content }">
            <gl-link href="blob/master/.gitlab-ci.yml" target="_blank">{{ content }}</gl-link>
          </template>
        </gl-sprintf>
      </p>
    </gl-modal>
  </div>
</template>

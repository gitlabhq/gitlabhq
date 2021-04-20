<script>
import { GlLink, GlModal, GlSprintf } from '@gitlab/ui';
import { s__ } from '~/locale';
import ModalCopyButton from '~/vue_shared/components/modal_copy_button.vue';

export default {
  components: {
    GlLink,
    GlModal,
    GlSprintf,
    ModalCopyButton,
  },
  inject: ['defaultBranchName'],
  props: {
    modalId: {
      type: String,
      required: true,
    },
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
    title: s__('ReviewApp|Enable Review App'),
  },
  computed: {
    modalInfoCopyStr() {
      return `deploy_review:
  stage: deploy
  script:
    - echo "Deploy a review app"
  environment:
    name: review/$CI_COMMIT_REF_NAME
    url: https://$CI_ENVIRONMENT_SLUG.example.com
  only:
    - branches
  except:
    - ${this.defaultBranchName}`;
    },
  },
};
</script>
<template>
  <gl-modal
    :modal-id="modalId"
    :title="$options.modalInfo.title"
    size="lg"
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
      <div class="gl-display-flex align-items-start">
        <pre class="gl-w-full" data-testid="enable-review-app-copy-string">
 {{ modalInfoCopyStr }} </pre
        >
        <modal-copy-button
          :title="$options.modalInfo.copyToClipboardText"
          :text="$options.modalInfo.copyString"
          :modal-id="modalId"
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
          <gl-link :href="`blob/${defaultBranchName}/.gitlab-ci.yml`" target="_blank">{{
            content
          }}</gl-link>
        </template>
      </gl-sprintf>
    </p>
  </gl-modal>
</template>

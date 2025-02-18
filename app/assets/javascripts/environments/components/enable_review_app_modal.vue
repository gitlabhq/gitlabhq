<script>
import { GlLink, GlModal, GlSprintf, GlIcon, GlPopover } from '@gitlab/ui';
import { uniqueId } from 'lodash';
import { helpPagePath } from '~/helpers/help_page_helper';
import ModalCopyButton from '~/vue_shared/components/modal_copy_button.vue';
import { REVIEW_APP_MODAL_I18N as i18n } from '../constants';

export default {
  components: {
    GlLink,
    GlModal,
    GlSprintf,
    GlIcon,
    GlPopover,
    ModalCopyButton,
  },
  model: {
    prop: 'visible',
    event: 'change',
  },
  props: {
    modalId: {
      type: String,
      required: true,
    },
    visible: {
      type: Boolean,
      required: false,
      default: false,
    },
  },
  data() {
    const modalInfoCopyId = uniqueId('enable-review-app-copy-string-');

    return { modalInfoCopyId };
  },
  computed: {
    modalInfoCopyStr() {
      return `deploy_review:
  stage: deploy
  script:
    - echo "Add script here that deploys the code to your infrastructure"
  environment:
    name: review/$CI_COMMIT_REF_NAME
    url: https://$CI_ENVIRONMENT_SLUG.example.com
  rules:
    - if: $CI_PIPELINE_SOURCE == "merge_request_event"`;
    },
  },
  methods: {
    commaOrPeriod(index, length) {
      return index + 1 === length ? '.' : ',';
    },
  },
  i18n,
  configuringReviewAppsPath: helpPagePath('ci/review_apps/_index.md', {
    anchor: 'configuring-review-apps',
  }),
  reviewAppsExamplesPath: helpPagePath('ci/review_apps/_index.md', {
    anchor: 'review-apps-examples',
  }),
};
</script>
<template>
  <gl-modal
    :visible="visible"
    :modal-id="modalId"
    :title="$options.i18n.title"
    static
    size="lg"
    hide-footer
    @change="$emit('change', $event)"
  >
    <p>{{ $options.i18n.intro }}</p>
    <p>
      <strong>{{ $options.i18n.instructions.title }}</strong>
    </p>
    <div class="gl-mb-6">
      <ol class="gl-px-6">
        <li>
          {{ $options.i18n.instructions.step1 }}
          <gl-icon
            ref="informationIcon"
            name="information-o"
            class="gl-text-blue-600 hover:gl-cursor-pointer"
          />
          <gl-popover
            :target="() => $refs.informationIcon.$el"
            :title="$options.i18n.staticSitePopover.title"
            triggers="hover focus"
          >
            {{ $options.i18n.staticSitePopover.body }}
          </gl-popover>
        </li>
        <li>{{ $options.i18n.instructions.step2 }}</li>
        <li>
          {{ $options.i18n.instructions.step3 }}
          <ul class="gl-px-4 gl-py-2">
            <li>{{ $options.i18n.instructions.step3a }}</li>
            <li>
              <gl-sprintf :message="$options.i18n.instructions.step3b">
                <template #code="{ content }"
                  ><code>{{ content }}</code></template
                >
              </gl-sprintf>
            </li>
            <li class="gl-list-none">
              <div class="align-items-start gl-flex">
                <pre
                  :id="modalInfoCopyId"
                  class="gl-w-full"
                  data-testid="enable-review-app-copy-string"
                  >{{ modalInfoCopyStr }}</pre
                >
                <modal-copy-button
                  :title="$options.i18n.copyToClipboardText"
                  :modal-id="modalId"
                  css-classes="border-0"
                  :target="`#${modalInfoCopyId}`"
                />
              </div>
            </li>
          </ul>
        </li>
        <li>{{ $options.i18n.instructions.step4 }}</li>
      </ol>
      <gl-link :href="$options.configuringReviewAppsPath" target="_blank">
        {{ $options.i18n.learnMore }}
        <gl-icon name="external-link" />
      </gl-link>
      <gl-link :href="$options.reviewAppsExamplesPath" target="_blank" class="gl-ml-6">
        {{ $options.i18n.viewMoreExampleProjects }}
        <gl-icon name="external-link" />
      </gl-link>
    </div>
  </gl-modal>
</template>

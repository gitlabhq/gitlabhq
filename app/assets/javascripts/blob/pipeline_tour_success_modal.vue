<script>
import { GlModal, GlSprintf, GlLink } from '@gitlab/ui';
import { sprintf, s__, __ } from '~/locale';
import Cookies from 'js-cookie';
import { glEmojiTag } from '~/emoji';

export default {
  beginnerLink:
    'https://about.gitlab.com/blog/2018/01/22/a-beginners-guide-to-continuous-integration/',
  exampleLink: 'https://docs.gitlab.com/ee/ci/examples/',
  bodyMessage: s__(
    'MR widget|The pipeline will now run automatically every time you commit code. Pipelines are useful for deploying static web pages, detecting vulnerabilities in dependencies, static or dynamic application security testing (SAST and DAST), and so much more!',
  ),
  modalTitle: sprintf(
    __("That's it, well done!%{celebrate}"),
    {
      celebrate: glEmojiTag('tada'),
    },
    false,
  ),
  components: {
    GlModal,
    GlSprintf,
    GlLink,
  },
  props: {
    goToPipelinesPath: {
      type: String,
      required: true,
    },
    commitCookie: {
      type: String,
      required: true,
    },
  },
  mounted() {
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
  <gl-modal
    visible
    size="sm"
    :title="$options.modalTitle"
    modal-id="success-pipeline-modal-id-not-used"
  >
    <p>
      {{ $options.bodyMessage }}
    </p>
    <gl-sprintf
      :message="
        s__(`MR widget|Take a look at our %{beginnerLinkStart}Beginner's Guide to Continuous Integration%{beginnerLinkEnd}
           and our %{exampleLinkStart}examples of GitLab CI/CD%{exampleLinkEnd}
           to see all the cool stuff you can do with it.`)
      "
    >
      <template #beginnerLink="{content}">
        <gl-link :href="$options.beginnerLink" target="_blank">
          {{ content }}
        </gl-link>
      </template>
      <template #exampleLink="{content}">
        <gl-link :href="$options.exampleLink" target="_blank">
          {{ content }}
        </gl-link>
      </template>
    </gl-sprintf>
    <template #modal-footer>
      <a :href="goToPipelinesPath" class="btn btn-success">{{ __('Go to Pipelines') }}</a>
    </template>
  </gl-modal>
</template>

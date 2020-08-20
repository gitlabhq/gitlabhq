<script>
import Cookies from 'js-cookie';
import { GlBanner } from '@gitlab/ui';
import { parseBoolean } from '~/lib/utils/common_utils';

export default {
  components: {
    GlBanner,
  },
  props: {
    surveyUrl: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      visible: true,
    };
  },
  created() {
    if (parseBoolean(Cookies.get('hide_serverless_survey'))) {
      this.visible = false;
    }
  },
  methods: {
    handleClose() {
      Cookies.set('hide_serverless_survey', 'true', { expires: 365 * 10 });
      this.visible = false;
    },
  },
};
</script>

<template>
  <gl-banner
    v-if="visible"
    class="mt-4"
    :title="s__('Serverless|Help shape the future of Serverless at GitLab')"
    :button-text="s__('Serverless|Sign up for First Look')"
    :button-link="surveyUrl"
    @close="handleClose"
  >
    <p>
      {{
        s__(
          'Serverless|We are continually striving to improve our Serverless functionality. As a Knative user, we would love to hear how we can make this experience better for you. Sign up for GitLab First Look today and we will be in touch shortly.',
        )
      }}
    </p>
  </gl-banner>
</template>

<script>
import { GlLink, GlLoadingIcon, GlSafeHtmlDirective as SafeHtml } from '@gitlab/ui';
import { mapState, mapActions, mapGetters } from 'vuex';
import { sprintf, s__ } from '~/locale';
import { CHECKING_INSTALLED } from '../constants';
import EmptyState from './empty_state.vue';
import EnvironmentRow from './environment_row.vue';

export default {
  components: {
    EnvironmentRow,
    EmptyState,
    GlLink,
    GlLoadingIcon,
  },
  directives: {
    SafeHtml,
  },
  computed: {
    ...mapState(['installed', 'isLoading', 'hasFunctionData', 'helpPath', 'statusPath']),
    ...mapGetters(['getFunctions']),

    checkingInstalled() {
      return this.installed === CHECKING_INSTALLED;
    },
    isInstalled() {
      return this.installed === true;
    },
    noServerlessConfigFile() {
      return sprintf(
        s__(
          'Serverless|Your repository does not have a corresponding %{startTag}serverless.yml%{endTag} file.',
        ),
        { startTag: '<code>', endTag: '</code>' },
        false,
      );
    },
    noGitlabYamlConfigured() {
      return sprintf(
        s__('Serverless|Your %{startTag}.gitlab-ci.yml%{endTag} file is not properly configured.'),
        { startTag: '<code>', endTag: '</code>' },
        false,
      );
    },
    mismatchedServerlessFunctions() {
      return sprintf(
        s__(
          "Serverless|The functions listed in the %{startTag}serverless.yml%{endTag} file don't match the namespace of your cluster.",
        ),
        { startTag: '<code>', endTag: '</code>' },
        false,
      );
    },
  },
  created() {
    this.fetchFunctions({
      functionsPath: this.statusPath,
    });
  },
  methods: {
    ...mapActions(['fetchFunctions']),
  },
};
</script>

<template>
  <section id="serverless-functions" class="flex-grow">
    <gl-loading-icon v-if="checkingInstalled" size="lg" class="gl-mt-3 gl-mb-3" />

    <div v-else-if="isInstalled">
      <div v-if="hasFunctionData">
        <div class="groups-list-tree-container js-functions-wrapper">
          <ul class="content-list group-list-tree">
            <environment-row
              v-for="(env, index) in getFunctions"
              :key="index"
              :env="env"
              :env-name="index"
            />
          </ul>
        </div>
        <gl-loading-icon v-if="isLoading" size="lg" class="gl-mt-3 gl-mb-3 js-functions-loader" />
      </div>
      <div v-else class="empty-state js-empty-state">
        <div class="text-content">
          <h4 class="state-title text-center">{{ s__('Serverless|No functions available') }}</h4>
          <p class="state-description">
            {{
              s__(
                'Serverless|There is currently no function data available from Knative. This could be for a variety of reasons including:',
              )
            }}
          </p>
          <ul>
            <li v-safe-html="noServerlessConfigFile"></li>
            <li v-safe-html="noGitlabYamlConfigured"></li>
            <li v-safe-html="mismatchedServerlessFunctions"></li>
            <li>{{ s__('Serverless|The deploy job has not finished.') }}</li>
          </ul>

          <p>
            {{
              s__(
                'Serverless|If you believe none of these apply, please check back later as the function data may be in the process of becoming available.',
              )
            }}
          </p>
          <div class="text-center">
            <gl-link :href="helpPath" class="btn btn-success">{{
              s__('Serverless|Learn more about Serverless')
            }}</gl-link>
          </div>
        </div>
      </div>
    </div>

    <empty-state v-else />
  </section>
</template>

<script>
import { mapState, mapActions, mapGetters } from 'vuex';
import { GlLoadingIcon } from '@gitlab/ui';
import FunctionRow from './function_row.vue';
import EnvironmentRow from './environment_row.vue';
import EmptyState from './empty_state.vue';

export default {
  components: {
    EnvironmentRow,
    FunctionRow,
    EmptyState,
    GlLoadingIcon,
  },
  props: {
    installed: {
      type: Boolean,
      required: true,
    },
    clustersPath: {
      type: String,
      required: true,
    },
    helpPath: {
      type: String,
      required: true,
    },
    statusPath: {
      type: String,
      required: true,
    },
  },
  computed: {
    ...mapState(['isLoading', 'hasFunctionData']),
    ...mapGetters(['getFunctions']),
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
  <section id="serverless-functions">
    <div v-if="installed">
      <div v-if="hasFunctionData">
        <gl-loading-icon
          v-if="isLoading"
          :size="2"
          class="prepend-top-default append-bottom-default"
        />
        <template v-else>
          <div class="groups-list-tree-container">
            <ul class="content-list group-list-tree">
              <environment-row
                v-for="(env, index) in getFunctions"
                :key="index"
                :env="env"
                :env-name="index"
              />
            </ul>
          </div>
        </template>
      </div>
      <div v-else class="empty-state js-empty-state">
        <div class="text-content">
          <h4 class="state-title text-center">{{ s__('Serverless|No functions available') }}</h4>
          <p class="state-description">
            {{
              s__(`Serverless|There is currently no function data available from Knative.
                   This could be for a variety of reasons including:`)
            }}
          </p>
          <ul>
            <li>Your repository does not have a corresponding <code>serverless.yml</code> file.</li>
            <li>Your <code>.gitlab-ci.yml</code> file is not properly configured.</li>
            <li>
              The functions listed in the <code>serverless.yml</code> file don't match the namespace
              of your cluster.
            </li>
            <li>The deploy job has not finished.</li>
          </ul>

          <p>
            {{
              s__(`Serverless|If you believe none of these apply, please check
                   back later as the function data may be in the process of becoming
                   available.`)
            }}
          </p>
          <div class="text-center">
            <a :href="helpPath" class="btn btn-success">
              {{ s__('Serverless|Learn more about Serverless') }}
            </a>
          </div>
        </div>
      </div>
    </div>

    <empty-state v-else :clusters-path="clustersPath" :help-path="helpPath" />
  </section>
</template>

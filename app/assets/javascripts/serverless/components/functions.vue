<script>
import { GlSkeletonLoading } from '@gitlab/ui';
import FunctionRow from './function_row.vue';
import EmptyState from './empty_state.vue';

export default {
  components: {
    FunctionRow,
    EmptyState,
    GlSkeletonLoading,
  },
  props: {
    functions: {
      type: Array,
      required: true,
      default: () => [],
    },
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
    loadingData: {
      type: Boolean,
      required: false,
      default: true,
    },
    hasFunctionData: {
      type: Boolean,
      required: false,
      default: true,
    },
  },
};
</script>

<template>
  <section id="serverless-functions">
    <div v-if="installed">
      <div v-if="hasFunctionData">
        <div class="ci-table js-services-list function-element">
          <div class="gl-responsive-table-row table-row-header" role="row">
            <div class="table-section section-20" role="rowheader">
              {{ s__('Serverless|Function') }}
            </div>
            <div class="table-section section-50" role="rowheader">
              {{ s__('Serverless|Domain') }}
            </div>
            <div class="table-section section-20" role="rowheader">
              {{ s__('Serverless|Runtime') }}
            </div>
            <div class="table-section section-10" role="rowheader">
              {{ s__('Serverless|Last Update') }}
            </div>
          </div>
          <template v-if="loadingData">
            <div v-for="j in 3" :key="j" class="gl-responsive-table-row">
              <gl-skeleton-loading />
            </div>
          </template>
          <template v-else>
            <function-row v-for="f in functions" :key="f.name" :func="f" />
          </template>
        </div>
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

<style>
.top-area {
  border-bottom: 0;
}

.function-element {
  border-bottom: 1px solid #e5e5e5;
  border-bottom-color: rgb(229, 229, 229);
  border-bottom-style: solid;
  border-bottom-width: 1px;
}
</style>

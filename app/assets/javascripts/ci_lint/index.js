import Vue from 'vue';
import VueApollo from 'vue-apollo';
import axios from '~/lib/utils/axios_utils';
import createDefaultClient from '~/lib/graphql';
import CiLint from './components/ci_lint.vue';

Vue.use(VueApollo);

const resolvers = {
  Mutation: {
    lintCI: (_, { endpoint, content, dry_run }) => {
      return axios.post(endpoint, { content, dry_run }).then(({ data }) => ({
        valid: data.valid,
        errors: data.errors,
        warnings: data.warnings,
        jobs: data.jobs.map(job => ({
          name: job.name,
          stage: job.stage,
          beforeScript: job.before_script,
          script: job.script,
          afterScript: job.after_script,
          tagList: job.tag_list,
          environment: job.environment,
          when: job.when,
          allowFailure: job.allow_failure,
          only: {
            refs: job.only.refs,
            __typename: 'CiLintJobOnlyPolicy',
          },
          except: job.except,
          __typename: 'CiLintJob',
        })),
        __typename: 'CiLintContent',
      }));
    },
  },
};

const apolloProvider = new VueApollo({
  defaultClient: createDefaultClient(resolvers),
});

export default (containerId = '#js-ci-lint') => {
  const containerEl = document.querySelector(containerId);
  const { endpoint, helpPagePath } = containerEl.dataset;

  return new Vue({
    el: containerEl,
    apolloProvider,
    render(createElement) {
      return createElement(CiLint, {
        props: {
          endpoint,
          helpPagePath,
        },
      });
    },
  });
};

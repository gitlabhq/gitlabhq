import diffGeneratedSubscription from '~/pages/projects/merge_requests/queries/diff_generated.subscription.graphql';

import createApolloClient from '../lib/graphql';

import { getDerivedMergeRequestInformation } from '../diffs/utils/merge_request';
import { EVT_MR_PREPARED, EVT_MR_DIFF_GENERATED } from '../diffs/constants';

import getMr from '../graphql_shared/queries/merge_request.query.graphql';
import mrPreparation from '../graphql_shared/subscriptions/merge_request_prepared.subscription.graphql';

function required(name) {
  throw new Error(`${name} is a required argument`);
}

async function observeMergeRequestFinishingPreparation({ apollo, signaler }) {
  const {
    namespace,
    project,
    id: iid,
  } = getDerivedMergeRequestInformation({
    endpoint: document.location.pathname,
  });
  const projectPath = `${namespace}/${project}`;

  if (projectPath && iid) {
    const currentStatus = await apollo.query({
      query: getMr,
      variables: { projectPath, iid },
    });

    if (!currentStatus.data.project) {
      return;
    }

    const { id: gqlMrId, preparedAt } = currentStatus.data.project.mergeRequest;
    let preparationObservable;
    let preparationSubscriber;

    if (!preparedAt) {
      preparationObservable = apollo.subscribe({
        query: mrPreparation,
        variables: {
          issuableId: gqlMrId,
        },
      });

      preparationSubscriber = preparationObservable.subscribe((preparationUpdate) => {
        if (preparationUpdate.data.mergeRequestMergeStatusUpdated?.preparedAt) {
          signaler.$emit(EVT_MR_PREPARED);
          preparationSubscriber.unsubscribe();
        }
      });
    } else {
      signaler.$emit(EVT_MR_DIFF_GENERATED, currentStatus.data.project.mergeRequest);
    }
  }
}

function observeMergeRequestDiffGenerated({ apollo, signaler }) {
  const tabCount = document.querySelector('.js-changes-tab-count');

  if (!tabCount || tabCount?.textContent !== '-') return;

  const susbription = apollo.subscribe({
    query: diffGeneratedSubscription,
    variables: {
      issuableId: tabCount.dataset.gid,
    },
  });

  const subscriber = susbription.subscribe(({ data: { mergeRequestDiffGenerated } }) => {
    if (mergeRequestDiffGenerated) {
      signaler.$emit(EVT_MR_DIFF_GENERATED, mergeRequestDiffGenerated);
      subscriber.unsubscribe();
    }
  });
}

export async function start({
  signalBus = required('signalBus'),
  apolloClient = createApolloClient(),
} = {}) {
  observeMergeRequestDiffGenerated({ signaler: signalBus, apollo: apolloClient });

  await observeMergeRequestFinishingPreparation({ signaler: signalBus, apollo: apolloClient });
}

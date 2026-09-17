import diffGeneratedSubscription from '~/pages/projects/merge_requests/queries/diff_generated.subscription.graphql';

import createApolloClient from '../lib/graphql';
import { parseBoolean } from '../lib/utils/common_utils';

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

  if (!projectPath || !iid) return;

  const renderedWhilePreparing = parseBoolean(
    document.querySelector('.js-changes-tab-count')?.dataset.preparing,
  );
  const getStatus = (fetchPolicy) =>
    apollo.query({ query: getMr, variables: { projectPath, iid }, fetchPolicy });

  const currentStatus = await getStatus();

  if (!currentStatus.data.project) return;

  const { id: gqlMrId, preparedAt } = currentStatus.data.project.mergeRequest;
  let preparationSubscriber;
  let prepared = false;

  // Both the subscription and a status query can report the MR as prepared: act on the first.
  const onPrepared = async (knownStatus) => {
    if (prepared) return;
    prepared = true;

    preparationSubscriber?.unsubscribe();
    signaler.$emit(EVT_MR_PREPARED);

    if (knownStatus) {
      signaler.$emit(EVT_MR_DIFF_GENERATED, knownStatus);
      return;
    }

    try {
      const { data } = await getStatus('network-only');
      if (data.project?.mergeRequest)
        signaler.$emit(EVT_MR_DIFF_GENERATED, data.project.mergeRequest);
    } catch {
      // noop: tab counts remain as `-` until the user refreshes
    }
  };

  if (preparedAt) {
    // Preparation finished between the server render and this query, so no broadcast follows it.
    if (renderedWhilePreparing) onPrepared(currentStatus.data.project.mergeRequest);
    else signaler.$emit(EVT_MR_DIFF_GENERATED, currentStatus.data.project.mergeRequest);
    return;
  }

  let recheckedOnAck = false;

  preparationSubscriber = apollo
    .subscribe({ query: mrPreparation, variables: { issuableId: gqlMrId } })
    .subscribe(async (preparationUpdate) => {
      if (preparationUpdate.data?.mergeRequestMergeStatusUpdated?.preparedAt) {
        onPrepared();
        return;
      }

      // The first payload acknowledges the subscription. Preparation that finished before the
      // subscription was registered never reached it, so the status is read once more.
      if (recheckedOnAck || !renderedWhilePreparing) return;
      recheckedOnAck = true;

      try {
        const { data } = await getStatus('network-only');
        if (data.project?.mergeRequest?.preparedAt) onPrepared(data.project.mergeRequest);
      } catch {
        // noop: the subscription stays open for the broadcast
      }
    });
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

function normalize(processable) {
  const { entry } = processable;
  const offset = entry.rootBounds.bottom - entry.boundingClientRect.top;
  const direction =
    offset < 0 ? 'Up' : 'Down'; /* eslint-disable-line @gitlab/require-i18n-strings */

  return {
    ...processable,
    entry: {
      time: entry.time,
      type: entry.isIntersecting ? 'intersection' : `scroll${direction}`,
    },
  };
}

function sort({ entry: alpha }, { entry: beta }) {
  const diff = alpha.time - beta.time;
  let order = 0;

  if (diff < 0) {
    order = -1;
  } else if (diff > 0) {
    order = 1;
  } else if (alpha.type === 'intersection' && beta.type === 'scrollUp') {
    order = 2;
  } else if (alpha.type === 'scrollUp' && beta.type === 'intersection') {
    order = -2;
  }

  return order;
}

function filter(entry) {
  return entry.type !== 'scrollDown';
}

export function discussionIntersectionObserverHandlerFactory() {
  let unprocessed = [];
  let timer = null;

  return (processable) => {
    unprocessed.push(processable);

    if (timer) {
      clearTimeout(timer);
    }

    timer = setTimeout(() => {
      unprocessed
        .map(normalize)
        .filter(filter)
        .sort(sort)
        .forEach((discussionObservationContainer) => {
          const {
            entry: { type },
            currentDiscussion,
            isFirstUnresolved,
            isDiffsPage,
            functions: { setCurrentDiscussionId, getPreviousUnresolvedDiscussionId },
          } = discussionObservationContainer;

          if (type === 'intersection') {
            setCurrentDiscussionId(currentDiscussion.id);
          } else if (type === 'scrollUp') {
            setCurrentDiscussionId(
              isFirstUnresolved
                ? null
                : getPreviousUnresolvedDiscussionId(currentDiscussion.id, isDiffsPage),
            );
          }
        });

      unprocessed = [];
    }, 0);
  };
}

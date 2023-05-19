import { localTimeAgo } from '~/lib/utils/datetime_utility';

const STREAMING_ELEMENT_NAME = 'streaming-element';
const TIME_AGO_CLASS_NAME = 'js-timeago';

// Callback handler for intersections observed on timestamps.
const handleTimestampsIntersecting = (entries, observer) => {
  entries.forEach((entry) => {
    const { isIntersecting, target: timestamp } = entry;
    if (isIntersecting) {
      localTimeAgo([timestamp]);
      observer.unobserve(timestamp);
    }
  });
};

// Finds nodes containing the `js-timeago` class within a mutation list.
const findTimeAgoNodes = (mutationList) => {
  return mutationList.reduce((acc, mutation) => {
    [...mutation.addedNodes].forEach((node) => {
      if (node.classList?.contains(TIME_AGO_CLASS_NAME)) {
        acc.push(node);
      }
    });

    return acc;
  }, []);
};

// Callback handler for mutations observed on the streaming element.
const handleStreamingElementMutation = (mutationList) => {
  const timestamps = findTimeAgoNodes(mutationList);
  const timestampIntersectionObserver = new IntersectionObserver(handleTimestampsIntersecting, {
    rootMargin: `${window.innerHeight}px 0px`,
  });

  timestamps.forEach((timestamp) => timestampIntersectionObserver.observe(timestamp));
};

// Finds the streaming element within a mutation list.
const findStreamingElement = (mutationList) =>
  mutationList.find((mutation) =>
    [...mutation.addedNodes].find((node) => node.localName === STREAMING_ELEMENT_NAME),
  )?.target;

// Waits for the streaming element to become available on the rootElement.
const waitForStreamingElement = (rootElement) => {
  return new Promise((resolve) => {
    let element = document.querySelector(STREAMING_ELEMENT_NAME);

    if (element) {
      resolve(element);
      return;
    }

    const rootElementObserver = new MutationObserver((mutations) => {
      element = findStreamingElement(mutations);
      if (element) {
        resolve(element);
        rootElementObserver.disconnect();
      }
    });

    rootElementObserver.observe(rootElement, { childList: true, subtree: true });
  });
};

/**
 * Ensures relative (timeago) timestamps that are streamed are formatted correctly.
 *
 * Example: `May 12, 2020` → `3 years ago`
 */
export const handleStreamedRelativeTimestamps = async (rootElement) => {
  const streamingElement = await waitForStreamingElement(rootElement); // wait for streaming to start
  const streamingElementObserver = new MutationObserver(handleStreamingElementMutation);

  streamingElementObserver.observe(streamingElement, { childList: true, subtree: true });

  return () => streamingElementObserver.disconnect();
};

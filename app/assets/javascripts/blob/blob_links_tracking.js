import Tracking from '~/tracking';

function addBlobLinksTracking(containerSelector, eventsToTrack) {
  const containerEl = document.querySelector(containerSelector);

  if (!containerEl) {
    return;
  }

  const eventName = 'click_link';
  const label = 'file_line_action';

  containerEl.addEventListener('click', (e) => {
    eventsToTrack.forEach((event) => {
      if (e.target.matches(event.selector)) {
        Tracking.event(undefined, eventName, {
          label,
          property: event.property,
        });
      }
    });
  });
}

export default addBlobLinksTracking;

import Tracking from '~/tracking';

const eventsToTrack = [
  { selector: '.file-line-blame', property: 'blame' },
  { selector: '.file-line-num', property: 'link' },
];

function addBlobLinksTracking() {
  const containerEl = document.querySelector('.file-holder');

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

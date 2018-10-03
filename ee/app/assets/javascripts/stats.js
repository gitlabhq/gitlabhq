import $ from 'jquery';

const snowPlowEnabled = () => typeof window.snowplow === 'function';

const trackEvent = (category, eventName, additionalData = { label: '', property: '', value: '' }) => {
  if (!snowPlowEnabled()) {
    return;
  }

  if (!category || !eventName) {
    return;
  }

  const { label, property, value } = additionalData;

  try {
    window.snowplow(
      'trackStructEvent',
      category,
      eventName,
      label,
      property,
      value,
    );
  } catch (e) {
    // do nothing
  }
};

const bindTrackableContainer = (container = '', category = document.body.dataset.page) => {
  if (!snowPlowEnabled()) {
    return;
  }

  const clickHandler = (e) => {
    const target = e.currentTarget;
    const label = target.getAttribute('data-track-label');
    const property = target.getAttribute('data-track-property') || '';
    const eventName = target.getAttribute('data-track-event');
    let value = target.value || '';

    // overrides value for checkboxes
    if (target.type === 'checkbox') {
      value = target.checked;
    }

    // overrides value if data-track_value is set
    if (typeof target.getAttribute('data-track-value') !== 'undefined' && target.getAttribute('data-track-value') !== null) {
      value = target.getAttribute('data-track-value');
    }

    trackEvent(category, eventName, { label, property, value });
  };

  const trackableElements = document.querySelectorAll(`${container} [data-track-label]`);
  trackableElements.forEach(element => {
    element.addEventListener('click', (e) => clickHandler(e));
  });

  // jquery required for select2 events
  // see: https://github.com/select2/select2/issues/4686#issuecomment-264747428
  $(`${container} .select2[data-track-label]`).on('click', (e) => clickHandler(e));
};

export default {
  trackEvent,
  bindTrackableContainer,
};

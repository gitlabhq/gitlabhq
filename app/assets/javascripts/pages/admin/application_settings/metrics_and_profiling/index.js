import UsagePingPayload from './../usage_ping_payload';

document.addEventListener('DOMContentLoaded', () => {
  new UsagePingPayload(
    document.querySelector('.js-usage-ping-payload-trigger'),
    document.querySelector('.js-usage-ping-payload'),
  ).init();
});

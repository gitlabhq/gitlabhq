import { Tracker } from '~/tracking/tracker';

const MR_SURVEY_WAIT_DURATION = 10000;

const broadcastNotificationVisible = () => {
  // We don't want to clutter up the UI by displaying the survey when broadcast message(s)
  // are visible as well.
  return Boolean(document.querySelector('.js-broadcast-notification-message'));
};

export const initMrExperienceSurvey = () => {
  if (!gon.features?.mrExperienceSurvey) return;
  if (!gon.current_user_id) return;
  if (!Tracker.enabled()) return;
  if (broadcastNotificationVisible()) return;

  setTimeout(() => {
    // eslint-disable-next-line promise/catch-or-return
    import('./app').then(({ startMrSurveyApp }) => {
      startMrSurveyApp();
    });
  }, MR_SURVEY_WAIT_DURATION);
};

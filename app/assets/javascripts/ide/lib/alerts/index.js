import { isDefaultCiConfig } from '~/lib/utils/common_utils';
import { leftSidebarViews } from '../../constants';
import EnvironmentsMessage from './environments.vue';

const alerts = [
  {
    key: Symbol('ALERT_ENVIRONMENT'),
    show: (state, file) =>
      state.currentActivityView === leftSidebarViews.commit.name &&
      isDefaultCiConfig(file.path) &&
      state.environmentsGuidanceAlertDetected &&
      !state.environmentsGuidanceAlertDismissed,
    props: { variant: 'tip' },
    dismiss: ({ dispatch }) => dispatch('dismissEnvironmentsGuidance'),
    message: EnvironmentsMessage,
  },
];

export const findAlertKeyToShow = (...args) => alerts.find((x) => x.show(...args))?.key;

export const getAlert = (key) => alerts.find((x) => x.key === key);

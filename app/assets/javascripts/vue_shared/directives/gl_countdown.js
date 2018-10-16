import { formatTime } from '~/lib/utils/datetime_utility';

const updateRemainingTime = (el, binding) => {
  const { endDate } = binding.value;

  const remainingMilliseconds = new Date(endDate).getTime() - Date.now();
  if (remainingMilliseconds >= 0) {
    el.innerText = formatTime(remainingMilliseconds);
  }
};

export default {
  bind(el, binding) {
    updateRemainingTime(el, binding);
    el.dataset.countdownUpdateIntervalId = window.setInterval(
      () => updateRemainingTime(el, binding),
      1000,
    );
  },

  unbind(el) {
    window.clearInterval(el.dataset.countdownUpdateIntervalId);
  }
};

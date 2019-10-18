import Tracking from '~/tracking';

export default {
  bind(el, binding) {
    el.dataset.trackingOptions = JSON.stringify(binding.value || {});

    el.addEventListener('click', () => {
      const { category, action, label, property, value } = JSON.parse(el.dataset.trackingOptions);
      if (!category || !action) {
        return;
      }
      Tracking.event(category, action, { label, property, value });
    });
  },
  update(el, binding) {
    if (binding.value !== binding.oldValue) {
      el.dataset.trackingOptions = JSON.stringify(binding.value || {});
    }
  },
};

export async function initToastMessages() {
  const toasts = document.querySelectorAll('.js-toast-message');
  if (!toasts.length) {
    return;
  }

  const { default: showToast } = await import('~/vue_shared/plugins/global_toast');
  toasts.forEach((toast) => showToast(toast.dataset.message));
}

function toggleIframeAllowlist() {
  const checkbox = document.getElementById('application_setting_iframe_rendering_enabled');
  const allowlistGroup = document.getElementById('iframe-allowlist-group');

  if (!checkbox || !allowlistGroup) return;

  function updateVisibility() {
    if (checkbox.checked) {
      allowlistGroup.style.display = '';
    } else {
      allowlistGroup.style.display = 'none';
    }
  }

  updateVisibility();

  checkbox.addEventListener('change', updateVisibility);
}

export default function initIframeSettings() {
  toggleIframeAllowlist();
}

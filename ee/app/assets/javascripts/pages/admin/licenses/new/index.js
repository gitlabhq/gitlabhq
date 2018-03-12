import $ from 'jquery';

document.addEventListener('DOMContentLoaded', () => {
  const $licenseFile = $('.license-file');
  const $licenseKey = $('.license-key');

  const showLicenseType = () => {
    const $checkedFile = $('input[name="license_type"]:checked').val() === 'file';

    $licenseFile.toggle($checkedFile);
    $licenseKey.toggle(!$checkedFile);
  };

  $('input[name="license_type"]').on('change', showLicenseType);
  showLicenseType();
});

import UserCallout from '~/user_callout';

// eslint-disable-next-line no-new
new UserCallout({ className: 'js-mr-approval-callout' });

const initAutomaticRebaseSetting = () => {
  const setting = document.querySelector('.js-automatic-rebase-setting');
  const radios = document.querySelectorAll('input[name="project[merge_method]"]');

  if (!setting || !radios.length) return;

  const containers = {
    rebase_merge: document.querySelector('.js-rebase-merge-container'),
    ff: document.querySelector('.js-fast-forward-container'),
  };

  const updatePosition = (value) => {
    const target = containers[value];
    if (target) {
      target.appendChild(setting);
      setting.classList.add('gl-ml-6');
      setting.classList.remove('gl-hidden');
    } else {
      setting.classList.add('gl-hidden');
    }
  };

  radios.forEach((radio) => {
    radio.addEventListener('change', (e) => updatePosition(e.target.value));
  });

  const checked = document.querySelector('input[name="project[merge_method]"]:checked');
  if (checked) updatePosition(checked.value);
};

initAutomaticRebaseSetting();

import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import initGkeNamespace from '~/clusters/gke_cluster_namespace';

describe('GKE cluster namespace', () => {
  const changeEvent = new Event('change');
  const isHidden = (el) => el.classList.contains('hidden');
  const hasDisabledInput = (el) => el.querySelector('input').disabled;

  let glManagedCheckbox;
  let selfManaged;
  let glManaged;

  beforeEach(() => {
    setHTMLFixture(`
      <input class="js-gl-managed" type="checkbox" value="1" checked />
      <div class="js-namespace">
        <input type="text" />
      </div>
      <div class="js-namespace-prefixed">
        <input type="text" />
      </div>
    `);

    glManagedCheckbox = document.querySelector('.js-gl-managed');
    selfManaged = document.querySelector('.js-namespace');
    glManaged = document.querySelector('.js-namespace-prefixed');

    initGkeNamespace();
  });

  afterEach(() => {
    resetHTMLFixture();
  });

  describe('GKE cluster namespace toggles', () => {
    it('initially displays the GitLab-managed label and input', () => {
      expect(isHidden(glManaged)).toEqual(false);
      expect(hasDisabledInput(glManaged)).toEqual(false);

      expect(isHidden(selfManaged)).toEqual(true);
      expect(hasDisabledInput(selfManaged)).toEqual(true);
    });

    it('displays the self-managed label and input when the Gitlab-managed checkbox is unchecked', () => {
      glManagedCheckbox.checked = false;
      glManagedCheckbox.dispatchEvent(changeEvent);

      expect(isHidden(glManaged)).toEqual(true);
      expect(hasDisabledInput(glManaged)).toEqual(true);

      expect(isHidden(selfManaged)).toEqual(false);
      expect(hasDisabledInput(selfManaged)).toEqual(false);
    });

    it('displays the GitLab-managed label and input when the Gitlab-managed checkbox is checked', () => {
      glManagedCheckbox.checked = true;
      glManagedCheckbox.dispatchEvent(changeEvent);

      expect(isHidden(glManaged)).toEqual(false);
      expect(hasDisabledInput(glManaged)).toEqual(false);

      expect(isHidden(selfManaged)).toEqual(true);
      expect(hasDisabledInput(selfManaged)).toEqual(true);
    });
  });
});

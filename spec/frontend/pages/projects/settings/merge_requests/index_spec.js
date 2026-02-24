import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';

describe('Merge requests settings page', () => {
  const createFixture = (selectedMethod = 'merge') => {
    setHTMLFixture(`
      <form>
        <fieldset id="merge-method">
          <input type="radio" name="project[merge_method]" value="merge" ${selectedMethod === 'merge' ? 'checked' : ''}>
          <input type="radio" name="project[merge_method]" value="rebase_merge" ${selectedMethod === 'rebase_merge' ? 'checked' : ''}>
          <div class="js-rebase-merge-container" aria-live="polite"></div>
          <input type="radio" name="project[merge_method]" value="ff" ${selectedMethod === 'ff' ? 'checked' : ''}>
          <div class="js-fast-forward-container" aria-live="polite"></div>
        </fieldset>
        <fieldset id="merge-options">
          <div class="js-automatic-rebase-setting">
            <input type="checkbox" name="project[project_setting_attributes][automatic_rebase_enabled]">
          </div>
        </fieldset>
      </form>
    `);
  };

  afterEach(() => {
    resetHTMLFixture();
    jest.resetModules();
  });

  const loadScript = async () => {
    await import('~/pages/projects/settings/merge_requests/index');
  };

  describe('automatic rebase setting', () => {
    it('hides checkbox when merge commit is selected on load', async () => {
      createFixture('merge');
      await loadScript();

      expect(document.querySelector('.js-automatic-rebase-setting')).toHaveClass('gl-hidden');
    });

    it('moves checkbox to rebase_merge container when semi-linear is selected on load', async () => {
      createFixture('rebase_merge');
      await loadScript();

      const setting = document.querySelector('.js-automatic-rebase-setting');

      expect(setting.parentElement).toHaveClass('js-rebase-merge-container');
      expect(setting).not.toHaveClass('gl-hidden');
      expect(setting).toHaveClass('gl-ml-6');
    });

    it('moves checkbox to ff container when fast-forward is selected on load', async () => {
      createFixture('ff');
      await loadScript();

      const setting = document.querySelector('.js-automatic-rebase-setting');

      expect(setting.parentElement).toHaveClass('js-fast-forward-container');
      expect(setting).not.toHaveClass('gl-hidden');
      expect(setting).toHaveClass('gl-ml-6');
    });

    it('moves checkbox when radio selection changes', async () => {
      createFixture('merge');
      await loadScript();

      const ffRadio = document.querySelector('input[value="ff"]');
      ffRadio.checked = true;
      ffRadio.dispatchEvent(new Event('change'));

      const setting = document.querySelector('.js-automatic-rebase-setting');

      expect(setting.parentElement).toHaveClass('js-fast-forward-container');
      expect(setting).not.toHaveClass('gl-hidden');
    });

    it('hides checkbox when switching to merge commit', async () => {
      createFixture('ff');
      await loadScript();

      const mergeRadio = document.querySelector('input[value="merge"]');
      mergeRadio.checked = true;
      mergeRadio.dispatchEvent(new Event('change'));

      expect(document.querySelector('.js-automatic-rebase-setting')).toHaveClass('gl-hidden');
    });

    it('moves checkbox between containers when switching merge methods', async () => {
      createFixture('rebase_merge');
      await loadScript();

      let setting = document.querySelector('.js-automatic-rebase-setting');

      expect(setting.parentElement).toHaveClass('js-rebase-merge-container');

      const ffRadio = document.querySelector('input[value="ff"]');
      ffRadio.checked = true;
      ffRadio.dispatchEvent(new Event('change'));

      setting = document.querySelector('.js-automatic-rebase-setting');

      expect(setting.parentElement).toHaveClass('js-fast-forward-container');
    });
  });

  describe('when automatic rebase setting element is not present', () => {
    it('does not throw an error', async () => {
      setHTMLFixture(`
        <form>
          <input type="radio" name="project[merge_method]" value="merge" checked>
        </form>
      `);

      await expect(loadScript()).resolves.not.toThrow();
    });
  });
});

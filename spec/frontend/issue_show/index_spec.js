import initIssueableApp from '~/issue_show';

describe('Issue show index', () => {
  describe('initIssueableApp', () => {
    it('should initialize app with no potential XSS attack', () => {
      const d = document.createElement('div');
      d.id = 'js-issuable-app-initial-data';
      d.innerHTML = JSON.stringify({
        initialDescriptionHtml: '&lt;img src=x onerror=alert(1)&gt;',
      });
      document.body.appendChild(d);

      const alertSpy = jest.spyOn(window, 'alert');
      initIssueableApp();

      expect(alertSpy).not.toHaveBeenCalled();
    });
  });
});

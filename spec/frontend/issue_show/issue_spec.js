import initIssuableApp from '~/issue_show/issue';
import { parseIssuableData } from '~/issue_show/utils/parse_data';

describe('Issue show index', () => {
  describe('initIssueableApp', () => {
    // Warning: this test is currently faulty.
    // More details at https://gitlab.com/gitlab-org/gitlab/-/issues/241717
    // eslint-disable-next-line jest/no-disabled-tests
    it.skip('should initialize app with no potential XSS attack', () => {
      const d = document.createElement('div');
      d.id = 'js-issuable-app-initial-data';

      d.innerHTML = JSON.stringify({
        initialDescriptionHtml: '&lt;img src=x onerror=alert(1)&gt;',
      });

      document.body.appendChild(d);

      const alertSpy = jest.spyOn(window, 'alert');
      const issuableData = parseIssuableData();
      initIssuableApp(issuableData);

      expect(alertSpy).not.toHaveBeenCalled();
    });
  });
});

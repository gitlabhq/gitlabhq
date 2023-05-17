import htmlWhatsNewNotification from 'test_fixtures_static/whats_new_notification.html';
import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import { useLocalStorageSpy } from 'helpers/local_storage_helper';
import { setNotification, getVersionDigest } from '~/whats_new/utils/notification';

describe('~/whats_new/utils/notification', () => {
  useLocalStorageSpy();

  let wrapper;

  const findNotificationEl = () => wrapper.querySelector('.header-help');
  const findNotificationCountEl = () => wrapper.querySelector('.js-whats-new-notification-count');
  const getAppEl = () => wrapper.querySelector('.app');

  beforeEach(() => {
    setHTMLFixture(htmlWhatsNewNotification);
    wrapper = document.querySelector('.whats-new-notification-fixture-root');
  });

  afterEach(() => {
    wrapper.remove();
    resetHTMLFixture();
  });

  describe('setNotification', () => {
    const subject = () => setNotification(getAppEl());

    it("when storage key doesn't exist it adds notifications class", () => {
      const notificationEl = findNotificationEl();

      expect(notificationEl.classList).not.toContain('with-notifications');

      subject();

      expect(findNotificationCountEl()).not.toBe(null);
      expect(notificationEl.classList).toContain('with-notifications');
    });

    it('removes class and count element when storage key has current digest', () => {
      const notificationEl = findNotificationEl();
      notificationEl.classList.add('with-notifications');
      localStorage.setItem('display-whats-new-notification', 'version-digest');

      expect(findNotificationCountEl()).not.toBe(null);

      subject();

      expect(findNotificationCountEl()).toBe(null);
      expect(notificationEl.classList).not.toContain('with-notifications');
    });
  });

  describe('getVersionDigest', () => {
    it('retrieves the storage key data attribute from the el', () => {
      expect(getVersionDigest(getAppEl())).toBe('version-digest');
    });
  });
});

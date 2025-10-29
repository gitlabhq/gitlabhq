import MockAdapter from 'axios-mock-adapter';
import waitForPromises from 'helpers/wait_for_promises';
import { createAlert } from '~/alert';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_INTERNAL_SERVER_ERROR, HTTP_STATUS_OK } from '~/lib/utils/http_status';
import PersistentUserCallout from '~/persistent_user_callout';
import { visitUrl } from '~/lib/utils/url_utility';

jest.mock('~/alert');
jest.mock('~/lib/utils/url_utility');

describe('PersistentUserCallout', () => {
  const dismissEndpoint = '/dismiss';
  const featureName = 'feature';
  const groupId = '5';

  function createFixture() {
    const fixture = document.createElement('div');
    fixture.innerHTML = `
      <div
        class="container"
        data-dismiss-endpoint="${dismissEndpoint}"
        data-feature-id="${featureName}"
        data-group-id="${groupId}"
      >
        <button type="button" class="js-close js-close-primary"></button>
        <button type="button" class="js-close js-close-secondary"></button>
      </div>
    `;

    return fixture;
  }

  function createDeferredLinkFixture() {
    const fixture = document.createElement('div');
    fixture.innerHTML = `
      <div
        class="container"
        data-dismiss-endpoint="${dismissEndpoint}"
        data-feature-id="${featureName}"
        data-defer-links="true"
      >
        <button type="button" class="js-close"></button>
        <a href="/somewhere-pleasant" target="_blank" class="deferred-link">A link</a>
        <a href="/somewhere-else" target="_blank" class="normal-link">Another link</a>
      </div>
    `;

    return fixture;
  }

  describe('dismiss', () => {
    const buttons = {};
    let mockAxios;
    let persistentUserCallout;

    beforeEach(() => {
      const fixture = createFixture();
      const container = fixture.querySelector('.container');
      buttons.primary = fixture.querySelector('.js-close-primary');
      buttons.secondary = fixture.querySelector('.js-close-secondary');

      mockAxios = new MockAdapter(axios);
      persistentUserCallout = new PersistentUserCallout(container);

      jest.spyOn(persistentUserCallout.container, 'remove').mockImplementation(() => {});
    });

    afterEach(() => {
      mockAxios.restore();
      jest.clearAllMocks();
      sessionStorage.clear();
    });

    it.each`
      button
      ${'primary'}
      ${'secondary'}
    `('POSTs endpoint and removes container when clicking $button close', async ({ button }) => {
      mockAxios.onPost(dismissEndpoint).replyOnce(HTTP_STATUS_OK);

      buttons[button].click();

      await waitForPromises();

      expect(persistentUserCallout.container.remove).toHaveBeenCalled();
      expect(mockAxios.history.post[0].data).toBe(
        JSON.stringify({ feature_name: featureName, group_id: groupId }),
      );
    });

    it('removes parent container if hasWrapper data attribute present', async () => {
      const newFixture = createFixture();
      const newContainer = newFixture.querySelector('.container');
      newContainer.dataset.hasWrapper = 'true';

      mockAxios.onPost(dismissEndpoint).replyOnce(HTTP_STATUS_OK);

      const callout = new PersistentUserCallout(newContainer);
      jest.spyOn(callout.container.parentElement, 'remove').mockImplementation(() => {});

      expect(callout.calloutElement).toBe(newFixture);

      callout.container.querySelector('.js-close').click();
      await waitForPromises();

      expect(callout.container.parentElement.remove).toHaveBeenCalled();
    });

    it('invokes Flash when the dismiss request fails', async () => {
      mockAxios.onPost(dismissEndpoint).replyOnce(HTTP_STATUS_INTERNAL_SERVER_ERROR);

      buttons.primary.click();

      await waitForPromises();

      expect(persistentUserCallout.container.remove).not.toHaveBeenCalled();
      expect(createAlert).toHaveBeenCalledWith({
        message: 'An error occurred while dismissing the alert. Refresh the page and try again.',
      });
    });

    it('sets callout timestamp in session storage', async () => {
      const storageKey = `user_callout_dismissed_${groupId}_${featureName}`;
      expect(sessionStorage.getItem(storageKey)).toBe(null);

      mockAxios.onPost(dismissEndpoint).replyOnce(HTTP_STATUS_OK);

      buttons.primary.click();

      await waitForPromises();

      expect(sessionStorage.getItem(storageKey)).toEqual(expect.any(String));
    });
  });

  describe('checks session storage on init', () => {
    let persistentUserCallout;
    let container;
    let getStorageSpy;
    const storageKey = `user_callout_dismissed_${groupId}_${featureName}`;

    beforeEach(() => {
      getStorageSpy = jest.spyOn(Storage.prototype, 'getItem');

      const fixture = createFixture();
      container = fixture.querySelector('.container');

      sessionStorage.setItem(storageKey, new Date('2025-10-31').toISOString());
      jest.spyOn(container, 'remove').mockImplementation(() => {});

      persistentUserCallout = new PersistentUserCallout(container);
    });

    afterEach(() => {
      jest.clearAllMocks();
      sessionStorage.clear();
    });

    it('removes callout element if callout key is present', () => {
      expect(getStorageSpy).toHaveBeenCalledWith(storageKey);
      expect(persistentUserCallout.container.remove).toHaveBeenCalled();
    });
  });

  describe('deferred links', () => {
    let button;
    let deferredLink;
    let normalLink;
    let mockAxios;
    let persistentUserCallout;

    beforeEach(() => {
      const fixture = createDeferredLinkFixture();
      const container = fixture.querySelector('.container');
      button = fixture.querySelector('.js-close');
      deferredLink = fixture.querySelector('.deferred-link');
      normalLink = fixture.querySelector('.normal-link');
      mockAxios = new MockAdapter(axios);
      persistentUserCallout = new PersistentUserCallout(container);
      jest.spyOn(persistentUserCallout.container, 'remove').mockImplementation(() => {});
    });

    afterEach(() => {
      mockAxios.restore();
      sessionStorage.clear();
    });

    it('defers loading of a link until callout is dismissed', async () => {
      const { href } = deferredLink;
      mockAxios.onPost(dismissEndpoint).replyOnce(HTTP_STATUS_OK);

      deferredLink.click();

      await waitForPromises();

      expect(visitUrl).toHaveBeenCalledWith(href, true);
      expect(persistentUserCallout.container.remove).toHaveBeenCalled();
      expect(mockAxios.history.post[0].data).toBe(JSON.stringify({ feature_name: featureName }));
    });

    it('does not dismiss callout on non-deferred links', async () => {
      normalLink.click();

      await waitForPromises();

      expect(visitUrl).not.toHaveBeenCalled();
      expect(persistentUserCallout.container.remove).not.toHaveBeenCalled();
    });

    it('does not follow link when notification is closed', async () => {
      mockAxios.onPost(dismissEndpoint).replyOnce(HTTP_STATUS_OK);

      button.click();

      await waitForPromises();

      expect(visitUrl).not.toHaveBeenCalled();
      expect(persistentUserCallout.container.remove).toHaveBeenCalled();
    });
  });

  describe('factory', () => {
    it('returns an instance of PersistentUserCallout with the provided container property', () => {
      const fixture = createFixture();

      expect(PersistentUserCallout.factory(fixture) instanceof PersistentUserCallout).toBe(true);
    });

    it('returns undefined if container is falsey', () => {
      expect(PersistentUserCallout.factory()).toBe(undefined);
    });
  });
});

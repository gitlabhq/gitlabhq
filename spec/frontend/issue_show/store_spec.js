import Store from '~/issue_show/stores';
import updateDescription from '~/issue_show/utils/update_description';

jest.mock('~/issue_show/utils/update_description');

describe('Store', () => {
  let store;

  beforeEach(() => {
    store = new Store({
      descriptionHtml: '<p>This is a description</p>',
    });
  });

  describe('updateState', () => {
    beforeEach(() => {
      document.body.innerHTML = `
            <div class="detail-page-description content-block">
              <details open>
                <summary>One</summary>
              </details>
              <details>
                <summary>Two</summary>
              </details>
            </div>
          `;
    });

    afterEach(() => {
      document.getElementsByTagName('html')[0].innerHTML = '';
    });

    it('calls updateDetailsState', () => {
      store.updateState({ description: '' });

      expect(updateDescription).toHaveBeenCalledTimes(1);
    });
  });
});

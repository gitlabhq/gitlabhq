import { escape } from 'lodash';
import { setHTMLFixture } from 'helpers/fixtures';
import Wikis from '~/pages/shared/wikis/wikis';
import Tracking from '~/tracking';

describe('Wikis', () => {
  describe('trackPageView', () => {
    const trackingPage = 'projects:wikis:show';
    const trackingContext = { foo: 'bar' };
    const showPageHtmlFixture = `
      <div class="js-wiki-page-content" data-tracking-context="${escape(
        JSON.stringify(trackingContext),
      )}"></div>
    `;

    beforeEach(() => {
      setHTMLFixture(showPageHtmlFixture);
      document.body.dataset.page = trackingPage;
      jest.spyOn(Tracking, 'event').mockImplementation();

      Wikis.trackPageView();
    });

    it('sends the tracking event and context', () => {
      expect(Tracking.event).toHaveBeenCalledWith(trackingPage, 'view_wiki_page', {
        label: 'view_wiki_page',
        context: {
          schema: 'iglu:com.gitlab/wiki_page_context/jsonschema/1-0-1',
          data: trackingContext,
        },
      });
    });
  });
});

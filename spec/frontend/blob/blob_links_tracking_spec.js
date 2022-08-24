import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import addBlobLinksTracking from '~/blob/blob_links_tracking';
import Tracking from '~/tracking';

describe('Blob links Tracking', () => {
  const eventName = 'click_link';
  const label = 'file_line_action';

  const eventsToTrack = [
    { selector: '.file-line-blame', property: 'blame' },
    { selector: '.file-line-num', property: 'link' },
  ];

  const [blameLinkClickEvent, numLinkClickEvent] = eventsToTrack;

  beforeEach(() => {
    setHTMLFixture(`
    <div class="file-holder">
      <div class="line-links diff-line-num">
        <a href="#L5" class="file-line-blame"></a>
        <a id="L5" href="#L5" data-line-number="5" class="file-line-num">5</a>
      </div>
      <pre id="LC5">Line 5 content</pre>
    </div>
    `);
    addBlobLinksTracking();
    jest.spyOn(Tracking, 'event');
  });

  afterEach(() => {
    resetHTMLFixture();
  });

  it('tracks blame link click event', () => {
    const blameButton = document.querySelector(blameLinkClickEvent.selector);
    blameButton.click();

    expect(Tracking.event).toHaveBeenCalledWith(undefined, eventName, {
      label,
      property: blameLinkClickEvent.property,
    });
  });

  it('tracks num link click event', () => {
    const numLinkButton = document.querySelector(numLinkClickEvent.selector);
    numLinkButton.click();

    expect(Tracking.event).toHaveBeenCalledWith(undefined, eventName, {
      label,
      property: numLinkClickEvent.property,
    });
  });

  it("doesn't fire tracking if the user clicks on any element that is not a link", () => {
    const codeLine = document.querySelector('#LC5');
    codeLine.click();

    expect(Tracking.event).not.toHaveBeenCalled();
  });
});

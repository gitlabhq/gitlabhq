import { setHTMLFixture } from 'helpers/fixtures';
import { initDetailsButton } from '~/projects/commit_box/info/init_details_button';

const htmlFixture = `
    <span>
      <a href="#" class="js-details-expand">Expand</a>
      <span class="js-details-content hide">Some branch</span>
    </span>`;

describe('~/projects/commit_box/info/init_details_button', () => {
  const findExpandButton = () => document.querySelector('.js-details-expand');
  const findContent = () => document.querySelector('.js-details-content');

  beforeEach(() => {
    setHTMLFixture(htmlFixture);
    initDetailsButton();
  });

  describe('when clicking the expand button', () => {
    it('renders the content by removing the `hide` class', () => {
      expect(findContent().classList).toContain('hide');
      findExpandButton().click();
      expect(findContent().classList).not.toContain('hide');
    });

    it('hides the expand button by adding the `gl-display-none` class', () => {
      expect(findExpandButton().classList).not.toContain('gl-display-none');
      findExpandButton().click();
      expect(findExpandButton().classList).toContain('gl-display-none');
    });
  });
});

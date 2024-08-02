import { setHTMLFixture } from 'helpers/fixtures';
import { initDetailsButton } from '~/projects/commit_box/info/init_details_button';

const htmlFixture = `
    <span>
      <a href="#" class="js-details-expand"><span class="sub-element">Expand</span></a>
      <span class="js-details-content hide">Some branch</span>
    </span>`;

describe('~/projects/commit_box/info/init_details_button', () => {
  const findExpandButton = () => document.querySelector('.js-details-expand');
  const findContent = () => document.querySelector('.js-details-content');
  const findExpandSubElement = () => document.querySelector('.sub-element');

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

    it('hides the expand button by adding the `gl-hidden` class', () => {
      expect(findExpandButton().classList).not.toContain('gl-hidden');
      findExpandButton().click();
      expect(findExpandButton().classList).toContain('gl-hidden');
    });
  });

  describe('when user clicks on element inside of expand button', () => {
    it('renders the content by removing the `hide` class', () => {
      expect(findContent().classList).toContain('hide');
      findExpandSubElement().click();
      expect(findContent().classList).not.toContain('hide');
    });

    it('hides the expand button by adding the `gl-hidden` class', () => {
      expect(findExpandButton().classList).not.toContain('gl-hidden');
      findExpandSubElement().click();
      expect(findExpandButton().classList).toContain('gl-hidden');
    });
  });
});

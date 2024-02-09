import initAccordion from '~/accordion';
import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';

describe('Init Accordion component', () => {
  beforeEach(() => {
    setHTMLFixture(
      '<div class="js-accordion"><div class="accordion-item"><button><svg class="js-chevron-icon"></svg>Trigger</button></div></div>',
    );
    initAccordion(document.querySelector('.js-accordion'));
  });

  afterEach(() => resetHTMLFixture());

  const findAccordionTrigger = () => document.querySelector('button');
  const findAccordionItem = () => document.querySelector('.accordion-item');
  const findSvgIconLink = () => document.querySelector('use').getAttribute('xlink:href');

  describe('expanded', () => {
    beforeEach(() => findAccordionTrigger().click());

    it('adds a `show` class to the accordion item', () => {
      expect(findAccordionItem().classList.contains('show')).toBe(true);
    });

    it('renders a chevron-down icon', () => {
      expect(findSvgIconLink()).toContain('#chevron-down');
    });

    it('renders a button with the correct aria-expanded value', () => {
      expect(findAccordionTrigger().getAttribute('aria-expanded')).toBe('true');
    });
  });

  describe('collapsed', () => {
    beforeEach(() => {
      findAccordionTrigger().click(); // expands the accordion
      findAccordionTrigger().click(); // collapses the accordion
    });

    it('removes `show` class from the accordion item', () => {
      expect(findAccordionItem().classList.contains('show')).toBe(false);
    });

    it('renders a chevron-right icon', () => {
      expect(findSvgIconLink()).toContain('#chevron-right');
    });

    it('renders a button with the correct aria-expanded value', () => {
      expect(findAccordionTrigger().getAttribute('aria-expanded')).toBe('false');
    });
  });
});

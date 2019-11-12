import { setHTMLFixture } from '../../helpers/fixtures';
import { updateElementsVisibility } from '~/repository/utils/dom';

describe('updateElementsVisibility', () => {
  it('adds hidden class', () => {
    setHTMLFixture('<div class="js-test"></div>');

    updateElementsVisibility('.js-test', false);

    expect(document.querySelector('.js-test').classList).toContain('hidden');
  });

  it('removes hidden class', () => {
    setHTMLFixture('<div class="hidden js-test"></div>');

    updateElementsVisibility('.js-test', true);

    expect(document.querySelector('.js-test').classList).not.toContain('hidden');
  });
});

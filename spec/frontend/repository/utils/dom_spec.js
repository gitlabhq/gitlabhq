import { setHTMLFixture } from '../../helpers/fixtures';
import { updateElementsVisibility, updateFormAction } from '~/repository/utils/dom';

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

describe('updateFormAction', () => {
  it('updates form action', () => {
    setHTMLFixture('<form class="js-test" action="/"></form>');

    updateFormAction('.js-test', '/gitlab/create', '/test');

    expect(document.querySelector('.js-test').action).toBe('http://localhost/gitlab/create/test');
  });
});

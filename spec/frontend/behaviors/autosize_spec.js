import '~/behaviors/autosize';

function load() {
  document.dispatchEvent(new Event('DOMContentLoaded'));
}

jest.mock('~/helpers/startup_css_helper', () => {
  return {
    waitForCSSLoaded: jest.fn().mockImplementation(cb => cb.apply()),
  };
});

describe('Autosize behavior', () => {
  beforeEach(() => {
    setFixtures('<textarea class="js-autosize"></textarea>');
  });

  it('is applied to the textarea', () => {
    load();

    const textarea = document.querySelector('textarea');
    expect(textarea.classList).toContain('js-autosize-initialized');
  });
});

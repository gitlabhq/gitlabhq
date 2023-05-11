import redirectToCorrectPage from '~/blame/blame_redirect';
import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import { createAlert } from '~/alert';

jest.mock('~/alert');

describe('Blame page redirect', () => {
  beforeEach(() => {
    const url = 'https://gitlab.com/flightjs/Flight/-/blame/master/file.json';
    Object.defineProperty(window, 'location', {
      writable: true,
      value: {
        href: url,
        hash: '',
        search: '',
      },
    });

    setHTMLFixture(`<div class="js-per-page" data-per-page="1000"></div>`);
  });

  afterEach(() => {
    createAlert.mockClear();
    resetHTMLFixture();
  });

  it('performs redirect to further pages when needed', () => {
    window.location.hash = '#L1001';
    redirectToCorrectPage();
    expect(window.location.href).toMatch('?page=2');
  });

  it('performs redirect back to first page when needed', () => {
    window.location.href = 'https://gitlab.com/flightjs/Flight/-/blame/master/file.json';
    window.location.search = '?page=200';
    window.location.hash = '#L999';
    redirectToCorrectPage();
    expect(window.location.href).toMatch('?page=1');
  });

  it('doesn`t perform redirect when the line is still on page 1', () => {
    window.location.hash = '#L1000';
    redirectToCorrectPage();
    expect(window.location.href).not.toMatch('?page');
  });

  it('doesn`t perform redirect when "no_pagination" param is present', () => {
    window.location.href = 'https://gitlab.com/flightjs/Flight/-/blame/master/file.json';
    window.location.search = '?no_pagination=true';
    window.location.hash = '#L1001';
    redirectToCorrectPage();
    expect(window.location.href).not.toMatch('?page');
  });

  it('doesn`t perform redirect when perPage is not present', () => {
    setHTMLFixture(`<div class="js-per-page"></div>`);
    window.location.hash = '#L1001';
    redirectToCorrectPage();
    expect(window.location.href).not.toMatch('?page');
  });

  it('shows alert with a message', () => {
    window.location.hash = '#L1001';
    redirectToCorrectPage();
    expect(createAlert).toHaveBeenCalledWith({
      message: 'Please wait a few moments while we load the file history for this line.',
    });
  });
});

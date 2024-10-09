import * as Pikaday from 'pikaday';
import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import initDatePickers from '~/behaviors/date_picker';
import * as utils from '~/lib/utils/datetime_utility';

jest.mock('pikaday');
jest.mock('~/lib/utils/datetime_utility');

describe('date_picker behavior', () => {
  let pikadayMock;
  let parseMock;

  beforeEach(() => {
    pikadayMock = jest.spyOn(Pikaday, 'default');
    parseMock = jest.spyOn(utils, 'newDate');
    setHTMLFixture(`
      <div>
        <input class="datepicker" value="2020-10-01" />
      </div>
      <div>
        <input class="datepicker" value="" />
      </div>`);
  });

  afterEach(() => {
    resetHTMLFixture();
  });

  it('Instantiates Pickaday for every instance of a .datepicker class', () => {
    initDatePickers();

    expect(pikadayMock.mock.calls.length).toEqual(2);
    expect(parseMock.mock.calls).toEqual([['2020-10-01'], ['']]);
  });
});

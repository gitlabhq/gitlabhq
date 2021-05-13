import * as Pikaday from 'pikaday';
import initDatePickers from '~/behaviors/date_picker';
import * as utils from '~/lib/utils/datetime_utility';

jest.mock('pikaday');
jest.mock('~/lib/utils/datetime_utility');

describe('date_picker behavior', () => {
  let pikadayMock;
  let parseMock;

  beforeEach(() => {
    pikadayMock = jest.spyOn(Pikaday, 'default');
    parseMock = jest.spyOn(utils, 'parsePikadayDate');
    setFixtures(`
      <div>
        <input class="datepicker" value="2020-10-01" />
      </div>
      <div>
        <input class="datepicker" value="" />
      </div>`);
  });

  it('Instantiates Pickaday for every instance of a .datepicker class', () => {
    initDatePickers();

    expect(pikadayMock.mock.calls.length).toEqual(2);
    expect(parseMock.mock.calls).toEqual([['2020-10-01'], ['']]);
  });
});

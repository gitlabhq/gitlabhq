/* eslint-disable no-unused-expressions, no-prototype-builtins, no-new, no-shadow */

import $ from 'jquery';
import htmlEventFilter from 'test_fixtures_static/event_filter.html';
import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import Activities from '~/activities';
import Pager from '~/pager';

describe('Activities', () => {
  window.gon || (window.gon = {});
  const filters = [
    {
      id: 'all',
    },
    {
      id: 'push',
      name: 'push events',
    },
    {
      id: 'merged',
      name: 'merge events',
    },
    {
      id: 'comments',
    },
    {
      id: 'team',
    },
  ];

  function getEventName(index) {
    const filter = filters[index];
    return filter.hasOwnProperty('name') ? filter.name : filter.id;
  }

  function getSelector(index) {
    const filter = filters[index];
    return `#${filter.id}_event_filter`;
  }

  beforeEach(() => {
    setHTMLFixture(htmlEventFilter);
    jest.spyOn(Pager, 'init').mockImplementation(() => {});
    new Activities();
  });

  afterEach(() => {
    resetHTMLFixture();
  });

  for (let i = 0; i < filters.length; i += 1) {
    ((i) => {
      describe(`when selecting ${getEventName(i)}`, () => {
        beforeEach(() => {
          $(getSelector(i)).click();
        });

        for (let x = 0; x < filters.length; x += 1) {
          ((x) => {
            const shouldHighlight = i === x;
            const testName = shouldHighlight ? 'should highlight' : 'should not highlight';

            it(`${testName} ${getEventName(x)}`, () => {
              expect($(getSelector(x)).parent().hasClass('active')).toEqual(shouldHighlight);
            });
          })(x);
        }
      });
    })(i);
  }
});

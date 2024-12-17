/* eslint no-param-reassign: "off" */
import MockAdapter from 'axios-mock-adapter';
import $ from 'jquery';
import labelsFixture from 'test_fixtures/autocomplete_sources/labels.json';
import { setHTMLFixture, resetHTMLFixture } from 'helpers/fixtures';
import GfmAutoComplete, {
  escape,
  membersBeforeSave,
  highlighter,
  CONTACT_STATE_ACTIVE,
  CONTACTS_ADD_COMMAND,
  CONTACTS_REMOVE_COMMAND,
} from 'ee_else_ce/gfm_auto_complete';
import { initEmojiMock, clearEmojiMock } from 'helpers/emoji';
import '~/lib/utils/jquery_at_who';
import { TEST_HOST } from 'helpers/test_constants';
import waitForPromises from 'helpers/wait_for_promises';
import AjaxCache from '~/lib/utils/ajax_cache';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_INTERNAL_SERVER_ERROR, HTTP_STATUS_OK } from '~/lib/utils/http_status';
import {
  eventlistenersMockDefaultMap,
  crmContactsMock,
} from 'ee_else_ce_jest/gfm_auto_complete/mock_data';

const mockSpriteIcons = '/icons.svg';

describe('escape', () => {
  it.each`
    xssPayload                                           | escapedPayload
    ${'<script>alert(1)</script>'}                       | ${'&lt;script&gt;alert(1)&lt;/script&gt;'}
    ${'%3Cscript%3E alert(1) %3C%2Fscript%3E'}           | ${'&lt;script&gt; alert(1) &lt;/script&gt;'}
    ${'%253Cscript%253E alert(1) %253C%252Fscript%253E'} | ${'&lt;script&gt; alert(1) &lt;/script&gt;'}
  `(
    'escapes the input string correctly accounting for multiple encoding',
    ({ xssPayload, escapedPayload }) => {
      expect(escape(xssPayload)).toBe(escapedPayload);
    },
  );
});

describe('GfmAutoComplete', () => {
  const fetchDataMock = { fetchData: jest.fn() };
  let gfmAutoCompleteCallbacks = GfmAutoComplete.prototype.getDefaultCallbacks.call(fetchDataMock);

  let atwhoInstance;
  let sorterValue;
  let filterValue;

  const triggerDropdown = ($textarea, text) => {
    $textarea
      .trigger('focus')
      .val($textarea.val() + text)
      .caret('pos', -1);
    $textarea.trigger('keyup');

    jest.runOnlyPendingTimers();
  };

  beforeEach(() => {
    window.gon = { sprite_icons: mockSpriteIcons };
  });

  describe('DefaultOptions.filter', () => {
    let items;

    beforeEach(() => {
      jest.spyOn(fetchDataMock, 'fetchData');
      jest.spyOn($.fn.atwho.default.callbacks, 'filter').mockImplementation(() => {});
    });

    describe('assets loading', () => {
      beforeEach(() => {
        atwhoInstance = { setting: {}, $inputor: 'inputor', at: '~' };
        items = ['loading'];

        filterValue = gfmAutoCompleteCallbacks.filter.call(atwhoInstance, '', items);
      });

      it('should call the fetchData function without query', () => {
        expect(fetchDataMock.fetchData).toHaveBeenCalledWith('inputor', '~');
      });

      it('should not call the default atwho filter', () => {
        expect($.fn.atwho.default.callbacks.filter).not.toHaveBeenCalled();
      });

      it('should return the passed unfiltered items', () => {
        expect(filterValue).toEqual(items);
      });
    });

    describe('backend filtering', () => {
      beforeEach(() => {
        atwhoInstance = { setting: {}, $inputor: 'inputor', at: '[vulnerability:' };
        items = [];
      });

      describe('when loading', () => {
        beforeEach(() => {
          items = ['loading'];
          filterValue = gfmAutoCompleteCallbacks.filter.call(atwhoInstance, 'oldquery', items);
        });

        it('should call the fetchData function with query', () => {
          expect(fetchDataMock.fetchData).toHaveBeenCalledWith(
            'inputor',
            '[vulnerability:',
            'oldquery',
          );
        });

        it('should not call the default atwho filter', () => {
          expect($.fn.atwho.default.callbacks.filter).not.toHaveBeenCalled();
        });

        it('should return the passed unfiltered items', () => {
          expect(filterValue).toEqual(items);
        });
      });

      describe('when previous query is different from current one', () => {
        beforeEach(() => {
          gfmAutoCompleteCallbacks = GfmAutoComplete.prototype.getDefaultCallbacks.call({
            previousQuery: 'oldquery',
            ...fetchDataMock,
          });
          filterValue = gfmAutoCompleteCallbacks.filter.call(atwhoInstance, 'newquery', items);
        });

        it('should call the fetchData function with query', () => {
          expect(fetchDataMock.fetchData).toHaveBeenCalledWith(
            'inputor',
            '[vulnerability:',
            'newquery',
          );
        });

        it('should not call the default atwho filter', () => {
          expect($.fn.atwho.default.callbacks.filter).not.toHaveBeenCalled();
        });

        it('should return the passed unfiltered items', () => {
          expect(filterValue).toEqual(items);
        });
      });

      describe('when previous query is not different from current one', () => {
        beforeEach(() => {
          gfmAutoCompleteCallbacks = GfmAutoComplete.prototype.getDefaultCallbacks.call({
            previousQuery: 'oldquery',
            ...fetchDataMock,
          });
          filterValue = gfmAutoCompleteCallbacks.filter.call(
            atwhoInstance,
            'oldquery',
            items,
            'searchKey',
          );
        });

        it('should not call the fetchData function', () => {
          expect(fetchDataMock.fetchData).not.toHaveBeenCalled();
        });

        it('should call the default atwho filter', () => {
          expect($.fn.atwho.default.callbacks.filter).toHaveBeenCalledWith(
            'oldquery',
            items,
            'searchKey',
          );
        });
      });
    });
  });

  describe('fetchData', () => {
    const { fetchData } = GfmAutoComplete.prototype;
    let mock;

    beforeEach(() => {
      mock = new MockAdapter(axios);
      jest.spyOn(axios, 'get');
      jest.spyOn(AjaxCache, 'retrieve');
    });

    afterEach(() => {
      mock.restore();
    });

    describe('backend filtering', () => {
      describe('data is not in cache', () => {
        let context;

        beforeEach(() => {
          context = {
            isLoadingData: { '[vulnerability:': false },
            dataSources: { vulnerabilities: 'vulnerabilities_autocomplete_url' },
            cachedData: { '[vulnerability:': { other_query: [] } },
          };
        });

        it('should call axios with query', () => {
          fetchData.call(context, {}, '[vulnerability:', 'query');

          expect(axios.get).toHaveBeenCalledWith('vulnerabilities_autocomplete_url', {
            params: { search: 'query' },
            signal: expect.any(AbortSignal),
          });
        });

        it('should abort previous request and call axios again with another search query', () => {
          const abortSpy = jest.spyOn(AbortController.prototype, 'abort');

          fetchData.call(context, {}, '[vulnerability:', 'query');
          fetchData.call(context, {}, '[vulnerability:', 'query2');

          expect(axios.get).toHaveBeenCalledWith('vulnerabilities_autocomplete_url', {
            params: { search: 'query' },
            signal: expect.any(AbortSignal),
          });

          expect(abortSpy).toHaveBeenCalled();

          expect(axios.get).toHaveBeenCalledWith('vulnerabilities_autocomplete_url', {
            params: { search: 'query2' },
            signal: expect.any(AbortSignal),
          });
        });

        it.each([HTTP_STATUS_OK, HTTP_STATUS_INTERNAL_SERVER_ERROR])(
          'should set the loading state',
          async (responseStatus) => {
            mock.onGet('vulnerabilities_autocomplete_url').replyOnce(responseStatus);

            fetchData.call(context, {}, '[vulnerability:', 'query');

            expect(context.isLoadingData['[vulnerability:']).toBe(true);

            await waitForPromises();

            expect(context.isLoadingData['[vulnerability:']).toBe(false);
          },
        );
      });

      describe('data is in cache', () => {
        beforeEach(() => {
          const context = {
            isLoadingData: { '[vulnerability:': false },
            dataSources: { vulnerabilities: 'vulnerabilities_autocomplete_url' },
            cachedData: { '[vulnerability:': { query: [] } },
            loadData: () => {},
          };
          fetchData.call(context, {}, '[vulnerability:', 'query');
        });

        it('should not call axios', () => {
          expect(axios.get).not.toHaveBeenCalled();
        });
      });
    });

    describe('frontend filtering', () => {
      describe('data is not in cache', () => {
        beforeEach(() => {
          const context = {
            isLoadingData: { '/': false },
            dataSources: { commands: 'commands_autocomplete_url' },
            cachedData: {},
          };
          fetchData.call(context, {}, '/', 'query');
        });

        it('should call AjaxCache', () => {
          expect(AjaxCache.retrieve).toHaveBeenCalledWith('commands_autocomplete_url', true);
        });
      });

      describe('data is in cache', () => {
        beforeEach(() => {
          const context = {
            isLoadingData: { '/': false },
            dataSources: { issues: 'commands_autocomplete_url' },
            cachedData: { '/': [{}] },
            loadData: () => {},
          };
          fetchData.call(context, {}, '/', 'query');
        });

        it('should not call AjaxCache', () => {
          expect(AjaxCache.retrieve).not.toHaveBeenCalled();
        });
      });
    });
  });

  describe('DefaultOptions.sorter', () => {
    describe('assets loading', () => {
      let items;

      beforeEach(() => {
        jest.spyOn(GfmAutoComplete, 'isLoading').mockReturnValue(true);

        atwhoInstance = { setting: {} };
        items = [];

        sorterValue = gfmAutoCompleteCallbacks.sorter.call(atwhoInstance, '', items);
      });

      it('should disable highlightFirst', () => {
        expect(atwhoInstance.setting.highlightFirst).toBe(false);
      });

      it('should return the passed unfiltered items', () => {
        expect(sorterValue).toEqual(items);
      });
    });

    describe('assets finished loading', () => {
      beforeEach(() => {
        jest.spyOn(GfmAutoComplete, 'isLoading').mockReturnValue(false);
        jest.spyOn($.fn.atwho.default.callbacks, 'sorter').mockImplementation(() => {});
      });

      it('should enable highlightFirst if alwaysHighlightFirst is set', () => {
        atwhoInstance = { setting: { alwaysHighlightFirst: true } };

        gfmAutoCompleteCallbacks.sorter.call(atwhoInstance);

        expect(atwhoInstance.setting.highlightFirst).toBe(true);
      });

      it('should enable highlightFirst if a query is present', () => {
        atwhoInstance = { setting: {} };

        gfmAutoCompleteCallbacks.sorter.call(atwhoInstance, 'query');

        expect(atwhoInstance.setting.highlightFirst).toBe(true);
      });

      it('should call the default atwho sorter', () => {
        atwhoInstance = { setting: {} };

        const query = 'query';
        const items = [];
        const searchKey = 'searchKey';

        gfmAutoCompleteCallbacks.sorter.call(atwhoInstance, query, items, searchKey);

        expect($.fn.atwho.default.callbacks.sorter).toHaveBeenCalledWith(query, items, searchKey);
      });
    });
  });

  describe('DefaultOptions.beforeInsert', () => {
    const beforeInsert = (context, value) =>
      gfmAutoCompleteCallbacks.beforeInsert.call(context, value);

    beforeEach(() => {
      atwhoInstance = { setting: { skipSpecialCharacterTest: false } };
    });

    it('should not quote if value only contains alphanumeric charecters', () => {
      expect(beforeInsert(atwhoInstance, '@user1')).toBe('@user1');
      expect(beforeInsert(atwhoInstance, '~label1')).toBe('~label1');
    });

    it('should quote if value contains any non-alphanumeric characters', () => {
      expect(beforeInsert(atwhoInstance, '~label-20')).toBe('~"label-20"');
      expect(beforeInsert(atwhoInstance, '~label 20')).toBe('~"label 20"');
    });

    it('should quote integer labels', () => {
      expect(beforeInsert(atwhoInstance, '~1234')).toBe('~"1234"');
    });

    it('escapes Markdown strikethroughs when needed', () => {
      expect(beforeInsert(atwhoInstance, '~a~bug')).toEqual('~"a~bug"');
      expect(beforeInsert(atwhoInstance, '~a~~bug~~')).toEqual('~"a\\~~bug\\~~"');
    });

    it('escapes Markdown emphasis when needed', () => {
      expect(beforeInsert(atwhoInstance, '~a_bug_')).toEqual('~a_bug\\_');
      expect(beforeInsert(atwhoInstance, '~a _bug_')).toEqual('~"a \\_bug\\_"');
      expect(beforeInsert(atwhoInstance, '~a*bug*')).toEqual('~"a\\*bug\\*"');
      expect(beforeInsert(atwhoInstance, '~a *bug*')).toEqual('~"a \\*bug\\*"');
    });

    it('escapes Markdown code spans when needed', () => {
      expect(beforeInsert(atwhoInstance, '~a`bug`')).toEqual('~"a\\`bug\\`"');
      expect(beforeInsert(atwhoInstance, '~a `bug`')).toEqual('~"a \\`bug\\`"');
    });
  });

  describe('DefaultOptions.matcher', () => {
    const defaultMatcher = (context, flag, subtext) =>
      gfmAutoCompleteCallbacks.matcher.call(context, flag, subtext);

    const flagsUseDefaultMatcher = ['@', '#', '!', '~', '%', '$'];
    const otherFlags = ['/', ':'];
    const flags = flagsUseDefaultMatcher.concat(otherFlags);

    const flagsHash = flags.reduce((hash, el) => {
      hash[el] = null;
      return hash;
    }, {});

    beforeEach(() => {
      atwhoInstance = { setting: {}, app: { controllers: flagsHash } };
    });

    const minLen = 1;
    const maxLen = 20;
    const argumentSize = [minLen, maxLen / 2, maxLen];

    const allowedSymbols = [
      '',
      'a',
      'n',
      'z',
      'A',
      'Z',
      'N',
      '0',
      '5',
      '9',
      'А',
      'а',
      'Я',
      'я',
      '.',
      "'",
      '-',
      '_',
    ];
    const jointAllowedSymbols = allowedSymbols.join('');

    describe('should match regular symbols', () => {
      flagsUseDefaultMatcher.forEach((flag) => {
        allowedSymbols.forEach((symbol) => {
          argumentSize.forEach((size) => {
            const query = new Array(size + 1).join(symbol);
            const subtext = flag + query;

            it(`matches argument "${flag}" with query "${subtext}"`, () => {
              expect(defaultMatcher(atwhoInstance, flag, subtext)).toBe(query);
            });
          });
        });

        it(`matches combination of allowed symbols for flag "${flag}"`, () => {
          const subtext = flag + jointAllowedSymbols;

          expect(defaultMatcher(atwhoInstance, flag, subtext)).toBe(jointAllowedSymbols);
        });
      });
    });

    describe('should not match special sequences', () => {
      const shouldNotBeFollowedBy = flags.concat(['\x00', '\x10', '\x3f', '\n', ' ']);
      const shouldNotBePrependedBy = ['`'];

      flagsUseDefaultMatcher.forEach((atSign) => {
        shouldNotBeFollowedBy.forEach((followedSymbol) => {
          const seq = atSign + followedSymbol;

          it(`should not match ${JSON.stringify(seq)}`, () => {
            expect(defaultMatcher(atwhoInstance, atSign, seq)).toBe(null);
          });
        });

        shouldNotBePrependedBy.forEach((prependedSymbol) => {
          const seq = prependedSymbol + atSign;

          it(`should not match "${seq}"`, () => {
            expect(defaultMatcher(atwhoInstance, atSign, seq)).toBe(null);
          });
        });
      });
    });
  });

  describe('DefaultOptions.highlighter', () => {
    beforeEach(() => {
      atwhoInstance = { setting: {} };
    });

    it('should return li if no query is given', () => {
      const liTag = '<li></li>';

      const highlightedTag = gfmAutoCompleteCallbacks.highlighter.call(atwhoInstance, liTag);

      expect(highlightedTag).toEqual(liTag);
    });

    it('should highlight search query in li element', () => {
      const liTag = '<li><img src="" />string</li>';
      const query = 's';

      const highlightedTag = gfmAutoCompleteCallbacks.highlighter.call(atwhoInstance, liTag, query);

      expect(highlightedTag).toEqual('<li><img src="" /> <strong>s</strong>tring </li>');
    });

    it('should highlight search query with special char in li element', () => {
      const liTag = '<li><img src="" />te.st</li>';
      const query = '.';

      const highlightedTag = gfmAutoCompleteCallbacks.highlighter.call(atwhoInstance, liTag, query);

      expect(highlightedTag).toEqual('<li><img src="" /> te<strong>.</strong>st </li>');
    });
  });

  describe('isLoading', () => {
    it('should be true with loading data object item', () => {
      expect(GfmAutoComplete.isLoading({ name: 'loading' })).toBe(true);
    });

    it('should be true with loading data array', () => {
      expect(GfmAutoComplete.isLoading(['loading'])).toBe(true);
    });

    it('should be true with loading data object array', () => {
      expect(GfmAutoComplete.isLoading([{ name: 'loading' }])).toBe(true);
    });

    it('should be false with actual array data', () => {
      expect(
        GfmAutoComplete.isLoading([{ title: 'events' }, { title: 'Bar' }, { title: 'Qux' }]),
      ).toBe(false);
    });

    it('should be false with actual data item', () => {
      expect(GfmAutoComplete.isLoading({ title: 'events' })).toBe(false);
    });
  });

  describe('membersBeforeSave', () => {
    const mockGroup = {
      username: 'my-group',
      name: 'My Group',
      count: 2,
      avatar_url: './group.jpg',
      type: 'Group',
      mentionsDisabled: false,
    };

    it('should return the original object when username is null', () => {
      expect(membersBeforeSave([{ ...mockGroup, username: null }])).toEqual([
        { ...mockGroup, username: null },
      ]);
    });

    it('should set the text avatar if avatar_url is null', () => {
      expect(membersBeforeSave([{ ...mockGroup, avatar_url: null }])).toEqual([
        {
          username: 'my-group',
          avatarTag: '<div class="avatar rect-avatar avatar-inline s24 gl-mr-2">M</div>',
          title: 'My Group (2)',
          search: 'MyGroup my-group',
          icon: '',
        },
      ]);
    });

    it('should set the image avatar if avatar_url is given', () => {
      expect(membersBeforeSave([mockGroup])).toEqual([
        {
          username: 'my-group',
          avatarTag:
            '<img src="./group.jpg" alt="my-group" class="avatar rect-avatar avatar-inline s24 gl-mr-2"/>',
          title: 'My Group (2)',
          search: 'MyGroup my-group',
          icon: '',
        },
      ]);
    });

    it('should set mentions disabled icon if mentionsDisabled is set', () => {
      expect(membersBeforeSave([{ ...mockGroup, mentionsDisabled: true }])).toEqual([
        {
          username: 'my-group',
          avatarTag:
            '<img src="./group.jpg" alt="my-group" class="avatar rect-avatar avatar-inline s24 gl-mr-2"/>',
          title: 'My Group',
          search: 'MyGroup my-group',
          icon: '<svg class="s16 vertical-align-middle gl-ml-2"><use xlink:href="/icons.svg#notifications-off" /></svg>',
        },
      ]);
    });

    it('should set the right image classes for User type members', () => {
      expect(
        membersBeforeSave([
          { username: 'my-user', name: 'My User', avatar_url: './users.jpg', type: 'User' },
        ]),
      ).toEqual([
        {
          username: 'my-user',
          avatarTag:
            '<img src="./users.jpg" alt="my-user" class="avatar  avatar-inline s24 gl-mr-2"/>',
          title: 'My User',
          search: 'MyUser my-user',
          icon: '',
        },
      ]);
    });
  });

  describe('Issues.insertTemplateFunction', () => {
    it('should return default template', () => {
      expect(GfmAutoComplete.Issues.insertTemplateFunction({ id: 5, title: 'Some Issue' })).toBe(
        '${atwho-at}${id}', // eslint-disable-line no-template-curly-in-string
      );
    });

    it('should return reference when reference is set', () => {
      expect(
        GfmAutoComplete.Issues.insertTemplateFunction({
          id: 5,
          title: 'Some Issue',
          reference: 'grp/proj#5',
        }),
      ).toBe('grp/proj#5');
    });
  });

  describe('Issues.templateFunction', () => {
    it('should return html with id and title', () => {
      expect(GfmAutoComplete.Issues.templateFunction({ id: 5, title: 'Some Issue' })).toBe(
        '<li><small>5</small> Some Issue</li>',
      );
    });

    it('should replace id with reference if reference is set', () => {
      expect(
        GfmAutoComplete.Issues.templateFunction({
          id: 5,
          title: 'Some Issue',
          reference: 'grp/proj#5',
        }),
      ).toBe('<li><small>grp/proj#5</small> Some Issue</li>');
    });

    it('should include an svg image when iconName is provided', () => {
      const expectedHtml = `<li><svg class="gl-fill-icon-subtle s16 gl-mr-2"><use xlink:href="/icons.svg#example-icon" /></svg><small>5</small> Some Issue</li>`;
      expect(
        GfmAutoComplete.Issues.templateFunction({
          id: 5,
          title: 'Some Issue',
          iconName: 'example-icon',
        }),
      ).toBe(expectedHtml);
    });

    it('escapes title in the template as it is user input', () => {
      expect(
        GfmAutoComplete.Issues.templateFunction({
          id: 5,
          title: '${search}<script>oh no $', // eslint-disable-line no-template-curly-in-string
        }),
      ).toBe('<li><small>5</small> &amp;dollar;{search}&lt;script&gt;oh no &amp;dollar;</li>');
    });
  });

  describe('GfmAutoComplete.Members', () => {
    const member = {
      name: 'Marge Simpson',
      username: 'msimpson',
      search: 'MargeSimpson msimpson',
    };

    describe('templateFunction', () => {
      it('should return html with avatarTag and username', () => {
        expect(
          GfmAutoComplete.Members.templateFunction({
            avatarTag: 'IMG',
            username: 'my-group',
            title: '',
            icon: '',
            availabilityStatus: '',
          }),
        ).toBe('<li>IMG my-group <small></small> </li>');
      });

      it('should add icon if icon is set', () => {
        expect(
          GfmAutoComplete.Members.templateFunction({
            avatarTag: 'IMG',
            username: 'my-group',
            title: '',
            icon: '<i class="icon"/>',
            availabilityStatus: '',
          }),
        ).toBe('<li>IMG my-group <small></small> <i class="icon"/></li>');
      });

      it('escapes title in the template as it is user input', () => {
        expect(
          GfmAutoComplete.Members.templateFunction({
            avatarTag: 'IMG',
            username: 'my-group',
            title: '${search}<script>oh no $', // eslint-disable-line no-template-curly-in-string
            icon: '<i class="icon"/>',
            availabilityStatus: '',
          }),
        ).toBe(
          '<li>IMG my-group <small>&amp;dollar;{search}&lt;script&gt;oh no &amp;dollar;</small> <i class="icon"/></li>',
        );
      });

      it('should add user availability status if availabilityStatus is set', () => {
        expect(
          GfmAutoComplete.Members.templateFunction({
            avatarTag: 'IMG',
            username: 'my-group',
            title: '',
            icon: '<i class="icon"/>',
            availabilityStatus:
              '<span class="badge badge-warning badge-pill gl-badge sm gl-ml-2">Busy</span>',
          }),
        ).toBe(
          '<li>IMG my-group <small><span class="badge badge-warning badge-pill gl-badge sm gl-ml-2">Busy</span></small> <i class="icon"/></li>',
        );
      });

      describe('nameOrUsernameStartsWith', () => {
        it.each`
          query             | result
          ${'mar'}          | ${true}
          ${'msi'}          | ${true}
          ${'margesimpson'} | ${true}
          ${'msimpson'}     | ${true}
          ${'arge'}         | ${false}
          ${'rgesimp'}      | ${false}
          ${'maria'}        | ${false}
          ${'homer'}        | ${false}
        `('returns $result for $query', ({ query, result }) => {
          expect(GfmAutoComplete.Members.nameOrUsernameStartsWith(member, query)).toBe(result);
        });
      });

      describe('nameOrUsernameIncludes', () => {
        it.each`
          query             | result
          ${'mar'}          | ${true}
          ${'msi'}          | ${true}
          ${'margesimpson'} | ${true}
          ${'msimpson'}     | ${true}
          ${'arge'}         | ${true}
          ${'rgesimp'}      | ${true}
          ${'maria'}        | ${false}
          ${'homer'}        | ${false}
        `('returns $result for $query', ({ query, result }) => {
          expect(GfmAutoComplete.Members.nameOrUsernameIncludes(member, query)).toBe(result);
        });
      });

      describe('sorter', () => {
        const query = 'c';

        const items = [
          { search: 'DougHackett elayne.krieger' },
          { search: 'BerylHuel cherie.block' },
          { search: 'ErlindaMayert nicolle' },
          { search: 'Administrator root' },
          { search: 'PhoebeSchaden salina' },
          { search: 'CatherinTerry tommy.will' },
          { search: 'AntoineLedner ammie' },
          { search: 'KinaCummings robena' },
          { search: 'CharlsieHarber xzbdulia' },
        ];

        const expected = [
          // Members whose name/username starts with `c` are grouped first
          { search: 'BerylHuel cherie.block' },
          { search: 'CatherinTerry tommy.will' },
          { search: 'CharlsieHarber xzbdulia' },
          // Members whose name/username contains `c` are grouped second
          { search: 'DougHackett elayne.krieger' },
          { search: 'ErlindaMayert nicolle' },
          { search: 'PhoebeSchaden salina' },
          { search: 'KinaCummings robena' },
        ];

        it('filters out non-matches, then puts matches with start of name/username first', () => {
          expect(GfmAutoComplete.Members.sort(query, items)).toMatchObject(expected);
        });
      });
    });
  });

  describe('GfmAutoComplete.Wikis', () => {
    const wikiPage1 = {
      title: 'My Wiki Page',
      slug: 'my-wiki-page',
      path: '/path/to/project/-/wikis/my-wiki-page',
    };
    const wikiPage2 = {
      title: 'Home',
      slug: 'home',
      path: '/path/to/project/-/wikis/home',
    };

    describe('templateFunction', () => {
      it('shows both title and slug, if they are different', () => {
        expect(GfmAutoComplete.Wikis.templateFunction(wikiPage1)).toMatchInlineSnapshot(`
          <li>
            <svg
              class="gl-mr-2 s16 vertical-align-middle"
            >
              <use
                xlink:href="/icons.svg#document"
              />
            </svg>
            My Wiki Page
            <small>
              (my-wiki-page)
            </small>
          </li>
        `);
      });

      it('shows only title, if title and slug are the same', () => {
        expect(GfmAutoComplete.Wikis.templateFunction(wikiPage2)).toMatchInlineSnapshot(`
          <li>
            <svg
              class="gl-mr-2 s16 vertical-align-middle"
            >
              <use
                xlink:href="/icons.svg#document"
              />
            </svg>
            Home
          </li>
        `);
      });
    });
  });

  describe('labels', () => {
    const dataSources = {
      labels: `${TEST_HOST}/autocomplete_sources/labels`,
    };

    const allLabels = labelsFixture;
    const assignedLabels = allLabels.filter((label) => label.set);
    const unassignedLabels = allLabels.filter((label) => !label.set);

    let autocomplete;
    let $textarea;

    beforeEach(() => {
      setHTMLFixture('<textarea></textarea>');
      autocomplete = new GfmAutoComplete(dataSources);
      $textarea = $('textarea');
      autocomplete.setup($textarea, { labels: true });
    });

    afterEach(() => {
      autocomplete.destroy();
      resetHTMLFixture();
    });

    const getDropdownItems = () => {
      const dropdown = document.getElementById('at-view-labels');
      const items = dropdown.getElementsByTagName('li');
      return [].map.call(items, (item) => item.textContent.trim());
    };

    const expectLabels = ({ input, output }) => {
      triggerDropdown($textarea, input);

      expect(getDropdownItems()).toEqual(output.map((label) => label.title));
    };

    describe('with no labels assigned', () => {
      beforeEach(() => {
        autocomplete.cachedData['~'] = [...unassignedLabels];
      });

      it.each`
        input           | output
        ${'~'}          | ${unassignedLabels}
        ${'/label ~'}   | ${unassignedLabels}
        ${'/labels ~'}  | ${unassignedLabels}
        ${'/relabel ~'} | ${unassignedLabels}
        ${'/unlabel ~'} | ${[]}
      `('$input shows $output.length labels', expectLabels);
    });

    describe('with some labels assigned', () => {
      beforeEach(() => {
        autocomplete.cachedData['~'] = allLabels;
      });

      it.each`
        input           | output
        ${'~'}          | ${allLabels}
        ${'/label ~'}   | ${unassignedLabels}
        ${'/labels ~'}  | ${unassignedLabels}
        ${'/relabel ~'} | ${allLabels}
        ${'/unlabel ~'} | ${assignedLabels}
      `('$input shows $output.length labels', expectLabels);
    });

    describe('with all labels assigned', () => {
      beforeEach(() => {
        autocomplete.cachedData['~'] = [...assignedLabels];
      });

      it.each`
        input           | output
        ${'~'}          | ${assignedLabels}
        ${'/label ~'}   | ${[]}
        ${'/labels ~'}  | ${[]}
        ${'/relabel ~'} | ${assignedLabels}
        ${'/unlabel ~'} | ${assignedLabels}
      `('$input shows $output.length labels', expectLabels);
    });

    it('escapes title in the template as it is user input', () => {
      const color = '#123456';
      const title = '${search}<script>oh no $'; // eslint-disable-line no-template-curly-in-string

      expect(GfmAutoComplete.Labels.templateFunction(color, title)).toBe(
        '<li><span class="dropdown-label-box" style="background: #123456"></span> &amp;dollar;{search}&lt;script&gt;oh no &amp;dollar;</li>',
      );
    });
  });

  describe('submit_review', () => {
    let autocomplete;
    let $textarea;

    const getDropdownItems = () => {
      const dropdown = document.getElementById('at-view-submit_review');

      return dropdown.getElementsByTagName('li');
    };

    beforeEach(() => {
      jest
        .spyOn(AjaxCache, 'retrieve')
        .mockReturnValue(Promise.resolve([{ name: 'submit_review' }]));

      setHTMLFixture('<textarea data-supports-quick-actions="true"></textarea>');
      autocomplete = new GfmAutoComplete({
        commands: `${TEST_HOST}/autocomplete_sources/commands`,
      });
      $textarea = $('textarea');
      autocomplete.setup($textarea, {});
    });

    afterEach(() => {
      autocomplete.destroy();
      resetHTMLFixture();
    });

    it('renders submit review options', async () => {
      triggerDropdown($textarea, '/');

      await waitForPromises();

      triggerDropdown($textarea, 'submit_review ');

      expect(getDropdownItems()).toHaveLength(3);
      expect(getDropdownItems()[0].textContent).toContain('Comment');
      expect(getDropdownItems()[1].textContent).toContain('Approve');
      expect(getDropdownItems()[2].textContent).toContain('Request changes');
    });
  });

  describe('emoji', () => {
    const mockItem = {
      'atwho-at': ':',
      emoji: {
        c: 'symbols',
        d: 'AB button (blood type)',
        e: '🆎',
        name: 'ab',
        u: '6.0',
      },
      fieldValue: 'ab',
    };

    beforeEach(async () => {
      await initEmojiMock();

      await new GfmAutoComplete({}).loadEmojiData({ atwho() {}, trigger() {} }, ':');
      if (!GfmAutoComplete.glEmojiTag) throw new Error('emoji not loaded');
    });

    afterEach(() => {
      clearEmojiMock();
    });

    describe('Emoji.templateFunction', () => {
      it('should return a correct template', () => {
        const actual = GfmAutoComplete.Emoji.templateFunction(mockItem);
        const glEmojiTag = `<gl-emoji data-name="${mockItem.emoji.name}"></gl-emoji>`;
        const expected = `<li>${glEmojiTag} ${mockItem.fieldValue}</li>`;

        expect(actual).toBe(expected);
      });
    });

    describe('Emoji.insertTemplateFunction', () => {
      it('should return a correct template', () => {
        const actual = GfmAutoComplete.Emoji.insertTemplateFunction(mockItem);
        const expected = `:${mockItem.emoji.name}:`;

        expect(actual).toBe(expected);
      });
    });
  });

  describe('milestones', () => {
    it('escapes title in the template as it is user input', () => {
      const expired = false;
      const title = '${search}<script>oh no $'; // eslint-disable-line no-template-curly-in-string

      expect(GfmAutoComplete.Milestones.templateFunction(title, expired)).toBe(
        '<li>&amp;dollar;{search}&lt;script&gt;oh no &amp;dollar;</li>',
      );
    });
  });

  describe('highlighter', () => {
    it('escapes regex', () => {
      const li = '<li>couple (woman,woman) <gl-emoji data-name="couple_ww"></gl-emoji></li>';

      expect(highlighter(li, ')')).toBe(
        '<li> couple (woman,woman<strong>)</strong>  <gl-emoji data-name="couple_ww"></gl-emoji></li>',
      );
    });
  });

  describe('CRM Contacts', () => {
    const dataSources = {
      contacts: `${TEST_HOST}/autocomplete_sources/contacts`,
    };

    const allContacts = crmContactsMock;
    const assignedContacts = allContacts.filter((contact) => contact.set);
    const unassignedContacts = allContacts.filter(
      (contact) => contact.state === CONTACT_STATE_ACTIVE && !contact.set,
    );

    let autocomplete;
    let $textarea;

    beforeEach(() => {
      setHTMLFixture('<textarea></textarea>');
      autocomplete = new GfmAutoComplete(dataSources);
      $textarea = $('textarea');
      autocomplete.setup($textarea, { contacts: true });
    });

    afterEach(() => {
      autocomplete.destroy();
      resetHTMLFixture();
    });

    const getDropdownItems = () => {
      const dropdown = document.getElementById('at-view-contacts');
      const items = dropdown.getElementsByTagName('li');
      return [].map.call(items, (item) => item.textContent.trim());
    };

    const expectContacts = ({ input, output }) => {
      triggerDropdown($textarea, input);

      expect(getDropdownItems()).toEqual(
        output.map((contact) => `${contact.first_name} ${contact.last_name} ${contact.email}`),
      );
    };

    describe('with no contacts assigned', () => {
      beforeEach(() => {
        autocomplete.cachedData['[contact:'] = [...unassignedContacts];
      });

      it.each`
        input                                     | output
        ${`${CONTACTS_ADD_COMMAND} [contact:`}    | ${unassignedContacts}
        ${`${CONTACTS_REMOVE_COMMAND} [contact:`} | ${[]}
      `('$input shows $output.length contacts', expectContacts);
    });

    describe('with some contacts assigned', () => {
      beforeEach(() => {
        autocomplete.cachedData['[contact:'] = allContacts;
      });

      it.each`
        input                                     | output
        ${`${CONTACTS_ADD_COMMAND} [contact:`}    | ${unassignedContacts}
        ${`${CONTACTS_REMOVE_COMMAND} [contact:`} | ${assignedContacts}
      `('$input shows $output.length contacts', expectContacts);
    });

    describe('with all contacts assigned', () => {
      beforeEach(() => {
        autocomplete.cachedData['[contact:'] = [...assignedContacts];
      });

      it.each`
        input                                     | output
        ${`${CONTACTS_ADD_COMMAND} [contact:`}    | ${[]}
        ${`${CONTACTS_REMOVE_COMMAND} [contact:`} | ${assignedContacts}
      `('$input shows $output.length contacts', expectContacts);
    });

    it('escapes name and email correct', () => {
      const xssPayload = '<script>alert(1)</script>';
      const escapedPayload = '&lt;script&gt;alert(1)&lt;/script&gt;';

      expect(
        GfmAutoComplete.Contacts.templateFunction({
          email: xssPayload,
          firstName: xssPayload,
          lastName: xssPayload,
        }),
      ).toBe(`<li><small>${escapedPayload} ${escapedPayload}</small> ${escapedPayload}</li>`);
    });
  });

  describe('autocomplete show eventlisteners', () => {
    let $textarea;

    beforeEach(() => {
      setHTMLFixture('<textarea></textarea>');
      $textarea = $('textarea');
    });

    it('sets correct eventlisteners when autocomplete features are enabled', () => {
      const autocomplete = new GfmAutoComplete({});
      autocomplete.setup($textarea);
      autocomplete.setupAtWho($textarea);
      /* eslint-disable-next-line no-underscore-dangle */
      const events = $._data($textarea[0], 'events');
      expect(
        Object.keys(events)
          .filter((x) => {
            return x.startsWith('shown');
          })
          .map((e) => {
            return { key: e, namespace: events[e][0].namespace };
          }),
      ).toEqual(expect.arrayContaining(eventlistenersMockDefaultMap));
    });

    it('sets no eventlisteners when features are disabled', () => {
      const autocomplete = new GfmAutoComplete({});
      autocomplete.setup($textarea, {});
      autocomplete.setupAtWho($textarea);
      /* eslint-disable-next-line no-underscore-dangle */
      const events = $._data($textarea[0], 'events');
      expect(
        Object.keys(events)
          .filter((x) => {
            return x.startsWith('shown');
          })
          .map((e) => {
            return { key: e, namespace: events[e][0].namespace };
          }),
      ).toStrictEqual([]);
    });
  });

  describe('updateDataSources', () => {
    const dataSources = {
      labels: `${TEST_HOST}/autocomplete_sources/labels`,
      members: `${TEST_HOST}/autocomplete_sources/members`,
      commands: `${TEST_HOST}/autocomplete_sources/commands`,
      issues: `${TEST_HOST}/autocomplete_sources/issues`,
      mergeRequests: `${TEST_HOST}/autocomplete_sources/merge_requests`,
      epics: `${TEST_HOST}/autocomplete_sources/epics`,
    };

    let autocomplete;
    let $textarea;

    beforeEach(() => {
      setHTMLFixture('<textarea></textarea>');
      autocomplete = new GfmAutoComplete(dataSources);
      $textarea = $('textarea');
      autocomplete.setup($textarea, {
        labels: true,
        members: true,
        commands: true,
        issues: true,
        mergeRequests: true,
        epics: true,
      });
    });

    afterEach(() => {
      autocomplete.destroy();
      resetHTMLFixture();
    });

    it('should update dataSources correctly', () => {
      const newDataSources = {
        ...dataSources,
        labels: `${TEST_HOST}/autocomplete_sources/labels?type=WorkItem&work_item_type_id=6`,
        members: `${TEST_HOST}/autocomplete_sources/members?type=WorkItem&work_item_type_id=6`,
      };

      autocomplete.updateDataSources(newDataSources);

      expect(autocomplete.dataSources).toEqual(newDataSources);
    });
  });
});

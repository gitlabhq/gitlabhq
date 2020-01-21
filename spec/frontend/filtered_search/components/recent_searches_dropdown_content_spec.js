import Vue from 'vue';
import eventHub from '~/filtered_search/event_hub';
import RecentSearchesDropdownContent from '~/filtered_search/components/recent_searches_dropdown_content.vue';
import IssuableFilteredSearchTokenKeys from '~/filtered_search/issuable_filtered_search_token_keys';

const createComponent = propsData => {
  const Component = Vue.extend(RecentSearchesDropdownContent);

  return new Component({
    el: document.createElement('div'),
    propsData,
  });
};

// Remove all the newlines and whitespace from the formatted markup
const trimMarkupWhitespace = text => text.replace(/(\n|\s)+/gm, ' ').trim();

describe('RecentSearchesDropdownContent', () => {
  const propsDataWithoutItems = {
    items: [],
    allowedKeys: IssuableFilteredSearchTokenKeys.getKeys(),
  };
  const propsDataWithItems = {
    items: ['foo', 'author:@root label:~foo bar'],
    allowedKeys: IssuableFilteredSearchTokenKeys.getKeys(),
  };

  let vm;
  afterEach(() => {
    if (vm) {
      vm.$destroy();
    }
  });

  describe('with no items', () => {
    let el;

    beforeEach(() => {
      vm = createComponent(propsDataWithoutItems);
      el = vm.$el;
    });

    it('should render empty state', () => {
      expect(el.querySelector('.dropdown-info-note')).toBeDefined();

      const items = el.querySelectorAll('.filtered-search-history-dropdown-item');

      expect(items.length).toEqual(propsDataWithoutItems.items.length);
    });
  });

  describe('with items', () => {
    let el;

    beforeEach(() => {
      vm = createComponent(propsDataWithItems);
      el = vm.$el;
    });

    it('should render clear recent searches button', () => {
      expect(el.querySelector('.filtered-search-history-clear-button')).toBeDefined();
    });

    it('should render recent search items', () => {
      const items = el.querySelectorAll('.filtered-search-history-dropdown-item');

      expect(items.length).toEqual(propsDataWithItems.items.length);

      expect(
        trimMarkupWhitespace(
          items[0].querySelector('.filtered-search-history-dropdown-search-token').textContent,
        ),
      ).toEqual('foo');

      const item1Tokens = items[1].querySelectorAll('.filtered-search-history-dropdown-token');

      expect(item1Tokens.length).toEqual(2);
      expect(item1Tokens[0].querySelector('.name').textContent).toEqual('author:');
      expect(item1Tokens[0].querySelector('.value').textContent).toEqual('@root');
      expect(item1Tokens[1].querySelector('.name').textContent).toEqual('label:');
      expect(item1Tokens[1].querySelector('.value').textContent).toEqual('~foo');
      expect(
        trimMarkupWhitespace(
          items[1].querySelector('.filtered-search-history-dropdown-search-token').textContent,
        ),
      ).toEqual('bar');
    });
  });

  describe('if isLocalStorageAvailable is `false`', () => {
    let el;

    beforeEach(() => {
      const props = Object.assign({ isLocalStorageAvailable: false }, propsDataWithItems);

      vm = createComponent(props);
      el = vm.$el;
    });

    it('should render an info note', () => {
      const note = el.querySelector('.dropdown-info-note');
      const items = el.querySelectorAll('.filtered-search-history-dropdown-item');

      expect(note).toBeDefined();
      expect(note.innerText.trim()).toBe('This feature requires local storage to be enabled');
      expect(items.length).toEqual(propsDataWithoutItems.items.length);
    });
  });

  describe('computed', () => {
    describe('processedItems', () => {
      it('with items', () => {
        vm = createComponent(propsDataWithItems);
        const { processedItems } = vm;

        expect(processedItems.length).toEqual(2);

        expect(processedItems[0].text).toEqual(propsDataWithItems.items[0]);
        expect(processedItems[0].tokens).toEqual([]);
        expect(processedItems[0].searchToken).toEqual('foo');

        expect(processedItems[1].text).toEqual(propsDataWithItems.items[1]);
        expect(processedItems[1].tokens.length).toEqual(2);
        expect(processedItems[1].tokens[0].prefix).toEqual('author:');
        expect(processedItems[1].tokens[0].suffix).toEqual('@root');
        expect(processedItems[1].tokens[1].prefix).toEqual('label:');
        expect(processedItems[1].tokens[1].suffix).toEqual('~foo');
        expect(processedItems[1].searchToken).toEqual('bar');
      });

      it('with no items', () => {
        vm = createComponent(propsDataWithoutItems);
        const { processedItems } = vm;

        expect(processedItems.length).toEqual(0);
      });
    });

    describe('hasItems', () => {
      it('with items', () => {
        vm = createComponent(propsDataWithItems);
        const { hasItems } = vm;

        expect(hasItems).toEqual(true);
      });

      it('with no items', () => {
        vm = createComponent(propsDataWithoutItems);
        const { hasItems } = vm;

        expect(hasItems).toEqual(false);
      });
    });
  });

  describe('methods', () => {
    describe('onItemActivated', () => {
      let onRecentSearchesItemSelectedSpy;

      beforeEach(() => {
        onRecentSearchesItemSelectedSpy = jest.fn();
        eventHub.$on('recentSearchesItemSelected', onRecentSearchesItemSelectedSpy);

        vm = createComponent(propsDataWithItems);
      });

      afterEach(() => {
        eventHub.$off('recentSearchesItemSelected', onRecentSearchesItemSelectedSpy);
      });

      it('emits event', () => {
        expect(onRecentSearchesItemSelectedSpy).not.toHaveBeenCalled();
        vm.onItemActivated('something');

        expect(onRecentSearchesItemSelectedSpy).toHaveBeenCalledWith('something');
      });
    });

    describe('onRequestClearRecentSearches', () => {
      let onRequestClearRecentSearchesSpy;

      beforeEach(() => {
        onRequestClearRecentSearchesSpy = jest.fn();
        eventHub.$on('requestClearRecentSearches', onRequestClearRecentSearchesSpy);

        vm = createComponent(propsDataWithItems);
      });

      afterEach(() => {
        eventHub.$off('requestClearRecentSearches', onRequestClearRecentSearchesSpy);
      });

      it('emits event', () => {
        expect(onRequestClearRecentSearchesSpy).not.toHaveBeenCalled();
        vm.onRequestClearRecentSearches({ stopPropagation: () => {} });

        expect(onRequestClearRecentSearchesSpy).toHaveBeenCalled();
      });
    });
  });
});

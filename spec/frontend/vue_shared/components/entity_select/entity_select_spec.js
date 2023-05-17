import { nextTick } from 'vue';
import { GlCollapsibleListbox, GlFormGroup } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import EntitySelect from '~/vue_shared/components/entity_select/entity_select.vue';
import { QUERY_TOO_SHORT_MESSAGE } from '~/vue_shared/components/entity_select/constants';
import waitForPromises from 'helpers/wait_for_promises';

describe('EntitySelect', () => {
  let wrapper;
  let fetchItemsMock;
  let fetchInitialSelectionTextMock;

  // Mocks
  const itemMock = {
    text: 'selectedGroup',
    value: '1',
  };

  // Stubs
  const GlAlert = {
    template: '<div><slot /></div>',
  };

  // Props
  const label = 'label';
  const inputName = 'inputName';
  const inputId = 'inputId';
  const headerText = 'headerText';
  const defaultToggleText = 'defaultToggleText';

  // Finders
  const findListbox = () => wrapper.findComponent(GlCollapsibleListbox);
  const findInput = () => wrapper.findByTestId('input');

  // Helpers
  const createComponent = ({ props = {}, slots = {}, stubs = {} } = {}) => {
    wrapper = shallowMountExtended(EntitySelect, {
      propsData: {
        label,
        inputName,
        inputId,
        headerText,
        defaultToggleText,
        fetchItems: fetchItemsMock,
        ...props,
      },
      stubs: {
        GlAlert,
        EntitySelect,
        ...stubs,
      },
      slots,
    });
  };
  const openListbox = () => findListbox().vm.$emit('shown');
  const search = (searchString) => findListbox().vm.$emit('search', searchString);
  const selectGroup = async () => {
    openListbox();
    await nextTick();
    findListbox().vm.$emit('select', itemMock.value);
    return nextTick();
  };

  beforeEach(() => {
    fetchItemsMock = jest.fn().mockImplementation(() => ({ items: [itemMock], totalPages: 1 }));
  });

  describe('on mount', () => {
    it('calls the fetch function when the listbox is opened', async () => {
      createComponent();
      openListbox();
      await nextTick();

      expect(fetchItemsMock).toHaveBeenCalledTimes(1);
    });

    it("fetches the initially selected value's name", async () => {
      fetchInitialSelectionTextMock = jest.fn().mockImplementation(() => itemMock.text);
      createComponent({
        props: {
          fetchInitialSelectionText: fetchInitialSelectionTextMock,
          initialSelection: itemMock.value,
        },
      });
      await nextTick();

      expect(fetchInitialSelectionTextMock).toHaveBeenCalledTimes(1);
      expect(findListbox().props('toggleText')).toBe(itemMock.text);
    });
  });

  it("renders the error slot's content", () => {
    const selector = 'data-test-id="error-element"';
    createComponent({
      slots: {
        error: `<div ${selector} />`,
      },
    });

    expect(wrapper.find(`[${selector}]`).exists()).toBe(true);
  });

  it('renders the label slot if provided', () => {
    const testid = 'label-slot';
    createComponent({
      slots: {
        label: `<div data-testid="${testid}" />`,
      },
      stubs: {
        GlFormGroup,
      },
    });

    expect(wrapper.findByTestId(testid).exists()).toBe(true);
  });

  describe('selection', () => {
    it('uses the default toggle text while no group is selected', () => {
      createComponent();

      expect(findListbox().props('toggleText')).toBe(defaultToggleText);
    });

    describe('once a group is selected', () => {
      it('emits `input` event with the select value', async () => {
        createComponent();
        await selectGroup();
        expect(wrapper.emitted('input')[0]).toEqual(['1']);
      });

      it(`uses the selected group's name as the toggle text`, async () => {
        createComponent();
        await selectGroup();

        expect(findListbox().props('toggleText')).toBe(itemMock.text);
      });

      it(`uses the selected group's ID as the listbox' and input value`, async () => {
        createComponent();
        await selectGroup();

        expect(findListbox().attributes('selected')).toBe(itemMock.value);
        expect(findInput().attributes('value')).toBe(itemMock.value);
      });

      it(`on reset, falls back to the default toggle text`, async () => {
        createComponent();
        await selectGroup();

        findListbox().vm.$emit('reset');
        await nextTick();

        expect(findListbox().props('toggleText')).toBe(defaultToggleText);
      });

      it('emits `input` event with `null` on reset', async () => {
        createComponent();
        await selectGroup();

        findListbox().vm.$emit('reset');
        await nextTick();

        expect(wrapper.emitted('input')[2]).toEqual([null]);
      });
    });
  });

  describe('search', () => {
    it('sets `searching` to `true` when first opening the dropdown', async () => {
      createComponent();

      expect(findListbox().props('searching')).toBe(false);

      openListbox();
      await nextTick();

      expect(findListbox().props('searching')).toBe(true);
    });

    it('sets `searching` to `true` while searching', async () => {
      createComponent();

      expect(findListbox().props('searching')).toBe(false);

      search('foo');
      await nextTick();

      expect(findListbox().props('searching')).toBe(true);
    });

    it('fetches groups matching the search string', async () => {
      const searchString = 'searchString';
      createComponent();
      openListbox();

      expect(fetchItemsMock).toHaveBeenCalledTimes(1);

      fetchItemsMock.mockImplementation(() => ({ items: [], totalPages: 1 }));
      search(searchString);
      await nextTick();

      expect(fetchItemsMock).toHaveBeenCalledTimes(2);
    });

    it('shows a notice if the search query is too short', async () => {
      const searchString = 'a';
      createComponent();
      openListbox();
      search(searchString);
      await nextTick();

      expect(fetchItemsMock).toHaveBeenCalledTimes(1);
      expect(findListbox().props('noResultsText')).toBe(QUERY_TOO_SHORT_MESSAGE);
    });
  });

  describe('pagination', () => {
    const searchString = 'searchString';

    beforeEach(() => {
      let requestCount = 0;
      fetchItemsMock.mockImplementation((searchQuery, page) => {
        requestCount += 1;
        return {
          items: [
            {
              text: `Group [page: ${page} - search: ${searchQuery}]`,
              value: `id:${requestCount}`,
            },
          ],
          totalPages: 3,
        };
      });
      createComponent();
      openListbox();
      findListbox().vm.$emit('bottom-reached');
      return nextTick();
    });

    it('fetches the next page when bottom is reached', () => {
      expect(fetchItemsMock).toHaveBeenCalledTimes(2);
      expect(fetchItemsMock).toHaveBeenLastCalledWith('', 2);
    });

    it('fetches the first page when the search query changes', async () => {
      search(searchString);
      await nextTick();

      expect(fetchItemsMock).toHaveBeenCalledTimes(3);
      expect(fetchItemsMock).toHaveBeenLastCalledWith(searchString, 1);
    });

    it('retains the search query when infinite scrolling', async () => {
      search(searchString);
      await nextTick();
      findListbox().vm.$emit('bottom-reached');
      await nextTick();

      expect(fetchItemsMock).toHaveBeenCalledTimes(4);
      expect(fetchItemsMock).toHaveBeenLastCalledWith(searchString, 2);
    });

    it('pauses infinite scroll after fetching the last page', async () => {
      expect(findListbox().props('infiniteScroll')).toBe(true);

      findListbox().vm.$emit('bottom-reached');
      await waitForPromises();

      expect(findListbox().props('infiniteScroll')).toBe(false);
    });

    it('resumes infinite scroll when search query changes', async () => {
      findListbox().vm.$emit('bottom-reached');
      await waitForPromises();

      expect(findListbox().props('infiniteScroll')).toBe(false);

      search(searchString);
      await waitForPromises();

      expect(findListbox().props('infiniteScroll')).toBe(true);
    });
  });
});
